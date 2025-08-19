//SystemVerilog
module toggle_ff_count_enable (
    input wire clk,
    input wire rst_n,
    input wire count_en,
    input wire data_req_in,
    output wire data_ack_in,
    output reg data_req_out,
    input wire data_ack_out,
    output reg [3:0] q
);
    // Clock buffer tree to reduce fanout
    wire clk_buf1, clk_buf2, clk_buf3;
    
    // Buffer instantiation for clock
    CLKBUF u_clk_buf1 (.I(clk), .O(clk_buf1));
    CLKBUF u_clk_buf2 (.I(clk_buf1), .O(clk_buf2));
    CLKBUF u_clk_buf3 (.I(clk_buf1), .O(clk_buf3));
    
    // Buffers for reset with high fanout
    wire rst_n_buf1, rst_n_buf2, rst_n_buf3;
    
    // Buffer instantiation for reset
    BUF u_rst_buf1 (.I(rst_n), .O(rst_n_buf1));
    BUF u_rst_buf2 (.I(rst_n_buf1), .O(rst_n_buf2));
    BUF u_rst_buf3 (.I(rst_n_buf1), .O(rst_n_buf3));
    
    // Count enable with buffer to reduce fanout
    wire count_en_buf;
    BUF u_count_en_buf (.I(count_en), .O(count_en_buf));
    
    // Pipeline stage registers
    reg [3:0] q_stage1, q_stage2;
    reg count_en_stage1, count_en_stage2;
    reg data_req_stage1, data_req_stage2;
    reg data_processed;
    
    // Acknowledge input data when we can process it
    assign data_ack_in = !data_processed;
    
    // Stage 1: Increment calculation
    always @(posedge clk_buf1 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            q_stage1 <= 4'b0000;
            count_en_stage1 <= 1'b0;
            data_req_stage1 <= 1'b0;
            data_processed <= 1'b0;
        end
        else begin
            count_en_stage1 <= count_en_buf;
            
            if (data_req_in && !data_processed) begin
                data_req_stage1 <= 1'b1;
                data_processed <= 1'b1;
                
                if (count_en_buf)
                    q_stage1 <= q + 1'b1;
                else
                    q_stage1 <= q;
            end
            else if (!data_req_in) begin
                data_processed <= 1'b0;
                data_req_stage1 <= 1'b0;
            end
            else begin
                data_req_stage1 <= data_req_stage1;
            end
        end
    end
    
    // Stage 2: Result processing
    always @(posedge clk_buf2 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            q_stage2 <= 4'b0000;
            count_en_stage2 <= 1'b0;
            data_req_stage2 <= 1'b0;
        end
        else begin
            q_stage2 <= q_stage1;
            count_en_stage2 <= count_en_stage1;
            data_req_stage2 <= data_req_stage1;
        end
    end
    
    // Final output stage with req-ack handshake
    always @(posedge clk_buf3 or negedge rst_n_buf3) begin
        if (!rst_n_buf3) begin
            q <= 4'b0000;
            data_req_out <= 1'b0;
        end
        else if (data_req_stage2 && !data_req_out) begin
            q <= q_stage2;
            data_req_out <= 1'b1;
        end
        else if (data_req_out && data_ack_out) begin
            data_req_out <= 1'b0;
        end
    end

endmodule

// Clock buffer module
module CLKBUF (
    input wire I,
    output wire O
);
    assign O = I;
endmodule

// General buffer module
module BUF (
    input wire I,
    output wire O
);
    assign O = I;
endmodule