//SystemVerilog
module crc8_generator #(parameter DATA_W=8) (
    input clk, rst, en,
    input [DATA_W-1:0] data_in,
    input valid_in,
    output reg valid_out,
    output reg [7:0] crc_out
);

    // Pipeline stage 1: Calculate borrow and shift
    reg [7:0] crc_stage1;
    reg [7:0] data_stage1;
    reg borrow_stage1;
    reg [7:0] temp_result_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2: Perform subtraction based on borrow
    reg [7:0] next_crc_stage2;
    reg valid_stage2;
    
    // Stage 1: Calculate borrow and shifted value
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_stage1 <= 8'hFF;
            data_stage1 <= 8'h00;
            borrow_stage1 <= 1'b0;
            temp_result_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else if (en) begin
            crc_stage1 <= (valid_in) ? crc_out : crc_stage1;
            data_stage1 <= data_in;
            borrow_stage1 <= (valid_in) ? (crc_out[7] ^ data_in[7]) : borrow_stage1;
            temp_result_stage1 <= (valid_in) ? {crc_out[6:0], 1'b0} : temp_result_stage1;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Perform subtraction based on borrow
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            next_crc_stage2 <= 8'h00;
            valid_stage2 <= 1'b0;
        end else if (en) begin
            next_crc_stage2 <= (valid_stage1) ? (borrow_stage1 ? (temp_result_stage1 - 8'h07) : temp_result_stage1) : next_crc_stage2;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Output stage: Update final CRC value
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            crc_out <= 8'hFF;
            valid_out <= 1'b0;
        end else if (en) begin
            crc_out <= (valid_stage2) ? next_crc_stage2 : crc_out;
            valid_out <= valid_stage2;
        end
    end

endmodule