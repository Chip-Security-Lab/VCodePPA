//SystemVerilog
module compact_hamming(
    input i_clk, i_rst, i_en,
    input [3:0] i_data,
    output reg [6:0] o_code,
    output reg o_valid
);
    // Stage 1 registers
    reg [3:0] data_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [3:0] data_stage2;
    reg p1_stage2;
    reg valid_stage2;
    
    // Stage 3 registers
    reg [3:0] data_stage3;
    reg p1_stage3;
    reg p2_stage3;
    reg valid_stage3;
    
    // First pipeline stage
    always @(posedge i_clk) begin
        if (i_rst) begin
            data_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            data_stage1 <= i_en ? i_data : data_stage1;
            valid_stage1 <= i_en;
        end
    end
    
    // Second pipeline stage - calculate first parity bit
    always @(posedge i_clk) begin
        if (i_rst) begin
            data_stage2 <= 4'b0;
            p1_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            data_stage2 <= data_stage1;
            p1_stage2 <= ^{data_stage1[1], data_stage1[2], data_stage1[3]};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Third pipeline stage - calculate second parity bit
    always @(posedge i_clk) begin
        if (i_rst) begin
            data_stage3 <= 4'b0;
            p1_stage3 <= 1'b0;
            p2_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            data_stage3 <= data_stage2;
            p1_stage3 <= p1_stage2;
            p2_stage3 <= ^{data_stage2[0], data_stage2[2], data_stage2[3]};
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output stage - calculate final parity bit and form output
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_code <= 7'b0;
            o_valid <= 1'b0;
        end else begin
            if (valid_stage3) begin
                o_code <= {data_stage3[3:1], 
                          p1_stage3, 
                          data_stage3[0], 
                          p2_stage3, 
                          ^{data_stage3[0], data_stage3[1], data_stage3[3]}};
            end
            o_valid <= valid_stage3;
        end
    end
endmodule