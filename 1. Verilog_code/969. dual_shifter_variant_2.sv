//SystemVerilog
module dual_shifter (
    input CLK, nRST,
    input data_a, data_b,
    output [3:0] out_a, out_b
);
    reg [1:0] shifter_a_stage1, shifter_b_stage1;
    reg [3:0] shifter_a_stage2, shifter_b_stage2;
    reg valid_stage1, valid_stage2;
    
    always @(posedge CLK) begin
        if (!nRST) begin
            shifter_a_stage1 <= 2'b00;
            shifter_b_stage1 <= 2'b00;
            shifter_a_stage2 <= 4'b0000;
            shifter_b_stage2 <= 4'b0000;
            valid_stage1 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            shifter_a_stage1 <= {shifter_a_stage1[0], data_a};
            shifter_b_stage1 <= {data_b, shifter_b_stage1[1]};
            valid_stage1 <= 1'b1;
            
            if (valid_stage1) begin
                shifter_a_stage2 <= {shifter_a_stage1, shifter_a_stage2[1:0]};
                shifter_b_stage2 <= {shifter_b_stage2[3:2], shifter_b_stage1};
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    assign out_a = valid_stage2 ? shifter_a_stage2 : 4'b0000;
    assign out_b = valid_stage2 ? shifter_b_stage2 : 4'b0000;
endmodule