module DSP #(parameter A0REG = 0, A1REG = 1, B0REG = 0, B1REG = 1,
    CREG = 1, DREG = 1, MREG = 1, PREG = 1, CARRYINREG = 1, CARRYOUTREG = 1, OPMODEREG = 1,
    CARRYINSEL = "OPMODE5", B_INPUT = "DIRECT", RSTTYPE = "SYNC") (
    input CLK, 
    input [7 : 0] OPMODE,
    input CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP,
    input RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP,
    input [17 : 0] A, B, D,
    input [47 : 0] C, PCIN,
    input [17 : 0] BCIN,
    input CARRYIN,
    output [17 : 0] BCOUT,
    output [35 : 0] M,
    output [47 : 0] P, PCOUT,
    output CARRYOUT, CARRYOUTF
);
    // declaring the internal signals:
    wire CYI_in, CYI_out, CYO_in, CYO_out;
    wire [7 : 0] OPMODE_out;
    wire [17 : 0] A0_out, B0_in, B0_out, D_out, operation0_out, A1_out, B1_in, B1_out;
    wire [35 : 0] operation1_out, M_out;
    wire [47 : 0] C_out, operation2_out, P_out;
    reg [47 : 0]  X_out, Z_out;
    
    // STAGE 0: OPMODE reg
    reg_mux_block #(.BITS(8), .RSTTYPE(RSTTYPE), .SELECTION(OPMODEREG)) block_OPMODE (.clk(CLK), .rst(RSTOPMODE), .en(CEOPMODE), .in(OPMODE), .out(OPMODE_out));

    // STAGE 1:
    // A0 reg
    reg_mux_block #(.BITS(18), .RSTTYPE(RSTTYPE), .SELECTION(A0REG)) block_A0 (.clk(CLK), .rst(RSTA), .en(CEA), .in(A), .out(A0_out));
    // B0 reg
    assign B0_in = (B_INPUT == "DIRECT") ? B : (B_INPUT == "CASCADE") ? BCIN : 0;
    reg_mux_block #(.BITS(18), .RSTTYPE(RSTTYPE), .SELECTION(B0REG)) block_B0 (.clk(CLK), .rst(RSTB), .en(CEB), .in(B0_in), .out(B0_out));
    // C reg
    reg_mux_block #(.BITS(48), .RSTTYPE(RSTTYPE), .SELECTION(CREG)) block_C (.clk(CLK), .rst(RSTC), .en(CEC), .in(C), .out(C_out));
    // D reg
    reg_mux_block #(.BITS(18), .RSTTYPE(RSTTYPE), .SELECTION(DREG)) block_D (.clk(CLK), .rst(RSTD), .en(CED), .in(D), .out(D_out));

    // STAGE 2: 
    // Pre-Adder/Subtractor
    assign operation0_out = (OPMODE_out[6]) ? (D_out - B0_out) : (D_out + B0_out);
    // A1 reg
    reg_mux_block #(.BITS(18), .RSTTYPE(RSTTYPE), .SELECTION(A1REG)) block_A1 (.clk(CLK), .rst(RSTA), .en(CEA), .in(A0_out), .out(A1_out));
    // B1 reg
    assign B1_in = OPMODE_out[4] ? operation0_out : B0_out;
    reg_mux_block #(.BITS(18), .RSTTYPE(RSTTYPE), .SELECTION(B1REG)) block_B1 (.clk(CLK), .rst(RSTB), .en(CEB), .in(B1_in), .out(B1_out));
    assign BCOUT = B1_out;

    // STAGE 3:
    // Multiplier
    assign operation1_out = A1_out * B1_out;
    // M reg
    reg_mux_block #(.BITS(36), .RSTTYPE(RSTTYPE), .SELECTION(MREG)) block_M (.clk(CLK), .rst(RSTM), .en(CEM), .in(operation1_out), .out(M_out));
    assign M = M_out;
    // CYI reg
    assign CYI_in = (CARRYINSEL == "OPMODE5") ? OPMODE_out[5] : (CARRYINSEL == "CARRYIN") ? CARRYIN : 0;
    reg_mux_block #(.BITS(1), .RSTTYPE(RSTTYPE), .SELECTION(CARRYINREG)) block_CYI (.clk(CLK), .rst(RSTCARRYIN), .en(CECARRYIN), .in(CYI_in), .out(CYI_out));

    // STAGE 4:
    // X_mux
    always @(*) begin
        case (OPMODE_out[1 : 0])
            2'b00:      X_out = 0;
            2'b01:      X_out = M_out;
            2'b10:      X_out = P_out;
            2'b11:      X_out = {D_out, A1_out, B1_out};
            default:    X_out = 0;
        endcase
    end
    // Z_mux
    always @(*) begin
        case (OPMODE_out[3 : 2])
            2'b00:      Z_out = 0;
            2'b01:      Z_out = PCIN;
            2'b10:      Z_out = P_out;
            2'b11:      Z_out = C_out;
            default:    Z_out = 0;
        endcase
    end

    // STAGE 5:
    // Post-Adder/Subtractor
    assign {CYO_in, operation2_out} = (OPMODE_out[7]) ? (Z_out - (X_out + CYI_out)) : (Z_out + X_out + CYI_out);
    // P reg
    reg_mux_block #(.BITS(48), .RSTTYPE(RSTTYPE), .SELECTION(PREG)) block_P (.clk(CLK), .rst(RSTP), .en(CEP), .in(operation2_out), .out(P_out));
    // CYO reg
    reg_mux_block #(.BITS(1), .RSTTYPE(RSTTYPE), .SELECTION(CARRYOUTREG)) block_CYO (.clk(CLK), .rst(RSTCARRYIN), .en(CECARRYIN), .in(CYO_in), .out(CYO_out));
    // outputs
    assign P = P_out;
    assign PCOUT = P_out;
    assign CARRYOUT = CYO_out;
    assign CARRYOUTF = CYO_out;
endmodule