module pipelined_crossbar (
    input wire clock, reset,
    input wire [15:0] in0, in1, in2, in3,
    input wire [1:0] sel0, sel1, sel2, sel3,
    output wire [15:0] out0, out1, out2, out3
);
    // Stage 1: Input registration - using arrays for cleaner code
    reg [15:0] in_reg [0:3];
    reg [1:0] sel_reg [0:3];
    
    // Stage 2: Crossbar switching and output registration
    reg [15:0] out_reg [0:3];
    
    integer i;
    
    always @(posedge clock) begin
        if (reset) begin
            for (i = 0; i < 4; i = i + 1) begin
                in_reg[i] <= 16'h0000;
                sel_reg[i] <= 2'b00;
                out_reg[i] <= 16'h0000;
            end
        end else begin
            // Pipeline stage 1 - register inputs
            in_reg[0] <= in0; sel_reg[0] <= sel0;
            in_reg[1] <= in1; sel_reg[1] <= sel1;
            in_reg[2] <= in2; sel_reg[2] <= sel2;
            in_reg[3] <= in3; sel_reg[3] <= sel3;
            
            // Pipeline stage 2 - crossbar switching
            for (i = 0; i < 4; i = i + 1) begin
                out_reg[i] <= in_reg[sel_reg[i]]; // More efficient indexing
            end
        end
    end
    
    // Output assignments
    assign out0 = out_reg[0];
    assign out1 = out_reg[1];
    assign out2 = out_reg[2];
    assign out3 = out_reg[3];
endmodule