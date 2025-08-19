//SystemVerilog
module MIPI_DataAligner #(
    parameter IN_WIDTH = 16,
    parameter OUT_WIDTH = 32
)(
    input wire in_clk,
    input wire out_clk,
    input wire rst_n,
    input wire [IN_WIDTH-1:0] din,
    input wire din_valid,
    output wire [OUT_WIDTH-1:0] dout,
    output wire dout_valid
);

    reg [OUT_WIDTH-1:0] buffer_stage1;
    reg [3:0] fill_level_stage1;
    reg buffer_full_stage1;
    
    reg [OUT_WIDTH-1:0] fifo_data [0:3];
    reg [1:0] wr_ptr_stage2;
    reg [2:0] fifo_count_stage2;
    reg [OUT_WIDTH-1:0] buffer_stage2;
    reg [3:0] fill_level_stage2;
    
    reg [1:0] rd_ptr_stage3;
    reg [2:0] fifo_count_stage3;
    reg rd_valid_stage3;
    reg [OUT_WIDTH-1:0] rd_data_stage3;

    // Stage 1: Input Processing
    always @(posedge in_clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_stage1 <= {OUT_WIDTH{1'b0}};
            fill_level_stage1 <= 4'd0;
            buffer_full_stage1 <= 1'b0;
        end else if (din_valid) begin
            case ({fill_level_stage1 + IN_WIDTH >= OUT_WIDTH})
                1'b1: begin
                    buffer_full_stage1 <= 1'b1;
                    buffer_stage1 <= {buffer_stage1[IN_WIDTH-1:0], din};
                    fill_level_stage1 <= fill_level_stage1 + IN_WIDTH - OUT_WIDTH;
                end
                1'b0: begin
                    buffer_stage1 <= {buffer_stage1[OUT_WIDTH-IN_WIDTH-1:0], din};
                    fill_level_stage1 <= fill_level_stage1 + IN_WIDTH;
                    buffer_full_stage1 <= 1'b0;
                end
            endcase
        end
    end

    // Stage 2: FIFO Write
    always @(posedge in_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_stage2 <= 2'd0;
            fifo_count_stage2 <= 3'd0;
            buffer_stage2 <= {OUT_WIDTH{1'b0}};
            fill_level_stage2 <= 4'd0;
        end else begin
            buffer_stage2 <= buffer_stage1;
            fill_level_stage2 <= fill_level_stage1;
            
            case ({buffer_full_stage1, fifo_count_stage2 < 4})
                2'b11: begin
                    fifo_data[wr_ptr_stage2] <= {din, buffer_stage1[OUT_WIDTH-1:IN_WIDTH]};
                    wr_ptr_stage2 <= wr_ptr_stage2 + 1;
                    fifo_count_stage2 <= fifo_count_stage2 + 1;
                end
                default: begin
                    wr_ptr_stage2 <= wr_ptr_stage2;
                    fifo_count_stage2 <= fifo_count_stage2;
                end
            endcase
        end
    end

    // Stage 3: FIFO Read
    always @(posedge out_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_stage3 <= 2'd0;
            fifo_count_stage3 <= 3'd0;
            rd_valid_stage3 <= 1'b0;
            rd_data_stage3 <= {OUT_WIDTH{1'b0}};
        end else begin
            fifo_count_stage3 <= fifo_count_stage2;
            rd_valid_stage3 <= 1'b0;
            
            case (fifo_count_stage3 > 0)
                1'b1: begin
                    rd_data_stage3 <= fifo_data[rd_ptr_stage3];
                    rd_valid_stage3 <= 1'b1;
                    rd_ptr_stage3 <= rd_ptr_stage3 + 1;
                    fifo_count_stage3 <= fifo_count_stage3 - 1;
                end
                1'b0: begin
                    rd_data_stage3 <= rd_data_stage3;
                    rd_ptr_stage3 <= rd_ptr_stage3;
                    fifo_count_stage3 <= fifo_count_stage3;
                end
            endcase
        end
    end

    assign dout = rd_data_stage3;
    assign dout_valid = rd_valid_stage3;
endmodule