//SystemVerilog
module dual_shifter (
    input CLK, nRST,
    input data_a, data_b,
    output [3:0] out_a, out_b
);
    reg [3:0] shifter_a_stage2, shifter_b_stage2;
    reg valid_stage2;
    wire [1:0] next_shifter_a_stage1;
    wire [1:0] next_shifter_b_stage1;
    wire next_valid_stage1;
    
    // Combinational logic for stage 1
    assign next_shifter_a_stage1 = {shifter_a_stage2[1], data_a};
    assign next_shifter_b_stage1 = {data_b, shifter_b_stage2[2]};
    assign next_valid_stage1 = 1'b1;
    
    // Stage 2: Combined shift operations
    always @(posedge CLK) begin
        if (!nRST) begin
            shifter_a_stage2 <= 4'b0000;
            shifter_b_stage2 <= 4'b0000;
            valid_stage2 <= 1'b0;
        end else begin
            shifter_a_stage2 <= {next_shifter_a_stage1, shifter_a_stage2[1:0]};
            shifter_b_stage2 <= {shifter_b_stage2[3:2], next_shifter_b_stage1};
            valid_stage2 <= next_valid_stage1;
        end
    end
    
    assign out_a = valid_stage2 ? shifter_a_stage2 : 4'b0000;
    assign out_b = valid_stage2 ? shifter_b_stage2 : 4'b0000;
endmodule