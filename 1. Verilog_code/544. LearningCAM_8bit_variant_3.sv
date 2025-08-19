//SystemVerilog
module cam_4 (
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire [7:0] write_data,
    input wire [7:0] read_data,
    output reg match_flag
);

    // Stage 1: Data storage and write operation
    reg [7:0] data_a_stage1, data_b_stage1;
    reg write_en_stage1;
    reg [7:0] read_data_stage1;
    
    // Stage 2: First comparison
    reg [7:0] data_a_stage2, data_b_stage2;
    reg [7:0] read_data_stage2;
    reg comp_a_stage2, comp_b_stage2;
    
    // Stage 3: Final comparison and output
    reg comp_a_stage3, comp_b_stage3;
    
    // Stage 1 logic
    always @(posedge clk) begin
        if (rst) begin
            data_a_stage1 <= 8'b0;
            data_b_stage1 <= 8'b0;
            write_en_stage1 <= 1'b0;
            read_data_stage1 <= 8'b0;
        end else begin
            write_en_stage1 <= write_en;
            read_data_stage1 <= read_data;
            if (write_en) begin
                data_a_stage1 <= write_data;
                data_b_stage1 <= write_data;
            end
        end
    end
    
    // Stage 2 logic
    always @(posedge clk) begin
        if (rst) begin
            data_a_stage2 <= 8'b0;
            data_b_stage2 <= 8'b0;
            read_data_stage2 <= 8'b0;
            comp_a_stage2 <= 1'b0;
            comp_b_stage2 <= 1'b0;
        end else begin
            data_a_stage2 <= data_a_stage1;
            data_b_stage2 <= data_b_stage1;
            read_data_stage2 <= read_data_stage1;
            comp_a_stage2 <= (data_a_stage1 == read_data_stage1);
            comp_b_stage2 <= (data_b_stage1 == read_data_stage1);
        end
    end
    
    // Stage 3 logic
    always @(posedge clk) begin
        if (rst) begin
            comp_a_stage3 <= 1'b0;
            comp_b_stage3 <= 1'b0;
            match_flag <= 1'b0;
        end else begin
            comp_a_stage3 <= comp_a_stage2;
            comp_b_stage3 <= comp_b_stage2;
            match_flag <= comp_a_stage2 || comp_b_stage2;
        end
    end
    
endmodule