module DSP_tb ();
    localparam A0REG = 0;           localparam A1REG = 1;
    localparam B0REG = 0;           localparam B1REG = 1;
    localparam CREG = 1;            localparam DREG = 1;
    localparam MREG = 1;            localparam PREG = 1;
    localparam CARRYINREG = 1;           
    localparam CARRYOUTREG = 1;
    localparam OPMODEREG = 1;
    localparam CARRYINSEL = "OPMODE5";
    localparam B_INPUT = "DIRECT";         
    localparam RSTTYPE = "SYNC";

    reg CLK, RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP;
    reg CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP, CARRYIN;
    reg [7 : 0] OPMODE;
    reg [17 : 0] BCIN, A, B, D;
    reg [47 : 0] PCIN, C;
    wire [17 : 0] BCOUT;
    wire [35 : 0] M;
    wire [47 : 0] PCOUT, P;
    wire CARRYOUT, CARRYOUTF;

    DSP #(.A0REG(A0REG), .A1REG(A1REG), .B0REG(B0REG), .B1REG(B1REG), .CREG(CREG), .DREG(DREG),
    .MREG(MREG), .PREG(PREG), .CARRYINREG(CARRYINREG), .CARRYOUTREG(CARRYOUTREG), .OPMODEREG(OPMODEREG),
    .CARRYINSEL(CARRYINSEL), .B_INPUT(B_INPUT), .RSTTYPE(RSTTYPE)) uut (.CLK(CLK), .OPMODE(OPMODE), .CEA(CEA),
    .CEB(CEB), .CEC(CEC), .CECARRYIN(CECARRYIN), .CED(CED), .CEM(CEM), .CEOPMODE(CEOPMODE), .CEP(CEP), .RSTA(RSTA),
    .RSTB(RSTB), .RSTC(RSTC), .RSTCARRYIN(RSTCARRYIN), .RSTD(RSTD), .RSTM(RSTM), .RSTOPMODE(RSTOPMODE), .RSTP(RSTP),
    .BCIN(BCIN), .PCIN(PCIN), .A(A), .B(B), .C(C), .D(D), .CARRYIN(CARRYIN), .BCOUT(BCOUT), .PCOUT(PCOUT), .M(M),
    .P(P), .CARRYOUT(CARRYOUT), .CARRYOUTF(CARRYOUTF));

    localparam CLK_PERIOD = 10;
    always
        #(CLK_PERIOD / 2)   CLK = ~CLK;
    
    reg [48 : 0] result;
    initial begin
        CLK = 1'b1;
        {RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP} = 8'b1111_1111;
        {CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP} = 8'b0000_0000;
        OPMODE = 8'b0011_1101;
         BCIN = 35;     PCIN = 150;
         A = 15;        B = 18;
         C = 200;       D = 25;
         CARRYIN = 1;
        // Checking reset inputs
        @(negedge CLK)  {RSTA, RSTB, RSTC, RSTCARRYIN, RSTD, RSTM, RSTOPMODE, RSTP} = 8'b0000_0000;    
        // Checking clock enable inputs
        @(negedge CLK)  {CEA, CEB, CEC, CECARRYIN, CED, CEM, CEOPMODE, CEP} = 8'b1111_1111;    
        
        /*  Case 1:  Pre-Adder, B1_reg takes the addition result, X chooses 
            the multiplication result, Z chooses C, Post-Adder  */
        // Checking the output of the seconed stage
        repeat(2) @(negedge CLK);
        result = 25 + 18;
        if (BCOUT != result) begin
            $monitor("ERROR");
            $stop;
        end
        // Checking the output of the third stage  
        @(negedge CLK);
        result = 15 * result;
        if (M != result) begin
            $monitor("ERROR");
            $stop;
        end
        // Checking the outputs of the final stage
        @(negedge CLK);
        result = result + 200 + 1;
        if ({CARRYOUT, P} != result) begin
            $monitor("ERROR");
            $stop;
        end
        // Changing C to show its direct relation to the outputs
        @(negedge CLK)  C = 150;    
        repeat(2) @(negedge CLK);
        result = result - 50;
        if ({CARRYOUT, P} != result) begin
            $monitor("ERROR");
            $stop;
        end

        /*  Case 2:  Pre-Subtractor, B1_reg takes the subtraction result,
            X choosesthe multiplication result, Z chooses C,
            Post-Subtractor  */
        OPMODE[7 : 6] = 2'b11;   
        // Checking the output of the seconed stage
        repeat(2) @(negedge CLK);
        result = 25 - 18;
        if (BCOUT != result) begin
            $monitor("ERROR");
            $stop;
        end
        // Checking the output of the third stage  
        @(negedge CLK);
        result = 15 * result;
        if (M != result) begin
            $monitor("ERROR");
            $stop;
        end
        // Checking the outputs of the final stage
        @(negedge CLK);
        result = 150 - (result + 1);
        if ({CARRYOUT, P} != result) begin
            $monitor("ERROR");
            $stop;
        end
       
        /*  Case 3:  Pre-Subtractor, B1_reg takes B, X chooses the multiplication
            result, Z chooses C, Post-Subtractor  */
        OPMODE[4] = 1'b0;       C = 500;
        // Checking the output of the seconed stage
        repeat(2) @(negedge CLK);
        result = 18;
        if (BCOUT != result) begin
            $monitor("ERROR");
            $stop;
        end
        // Checking the output of the third stage  
        @(negedge CLK);
        result = 15 * result;
        if (M != result) begin
            $monitor("ERROR");
            $stop;
        end
        // Checking the outputs of the final stage
        @(negedge CLK);
        result = 500 - (result + 1);
        if ({CARRYOUT, P} != result) begin
            $monitor("ERROR");
            $stop;
        end
        
        /*  Case 4:  Pre-Subtractor, B1_reg takes B, X chooses the D:B:A
            concatination, Z chooses C, Post-Subtractor  */
        OPMODE[1 : 0] = 2'b11;      A = 1;
        B  = 1;     D = 0;      C = 500_000;
        // Checking the output of the seconed stage
        repeat(2) @(negedge CLK);
        result = 1;
        if (BCOUT != result) begin
            $monitor("ERROR");
            $stop;
        end
        // Checking the output of the third stage  
        @(negedge CLK);
        result = 1 * result;
        if (M != result) begin
            $monitor("ERROR");
            $stop;
        end
        // Checking the outputs of the final stage
        @(negedge CLK);
        result = 500_000 - ({12'd0, 18'd1, 18'd1} + 1);
        if ({CARRYOUT, P} != result) begin
            $monitor("ERROR");
            $stop;
        end
        
        /*  Case 5:  Pre-Subtractor, B1_reg takes B, X chooses 0, 
            Z chooses PCIN, Post-ADDER*/
        OPMODE = 8'b0110_0100;       
        // Checking the outputs of the final stage
        repeat(2) @(negedge CLK);
        result = 150 + 1;
        if (P != result) begin
            $monitor("ERROR");
            $stop;
        end

        /*  Case 6:  Pre-Subtractor, B1_reg takes B, X chooses 0, 
            Z chooses P(Accumulator), Post-ADDER*/
        OPMODE[3 : 2] = 2'b10;       
        // Checking the outputs of the final stage
        @(negedge CLK);
        repeat(5) begin
            @(negedge CLK);
            result = result + 1;
            if (P != result) begin
                $monitor("ERROR");
                $stop;
            end
        end

        @(posedge CLK)  $stop;
    end
endmodule