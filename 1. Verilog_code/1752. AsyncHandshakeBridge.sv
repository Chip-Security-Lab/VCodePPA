module AsyncHandshakeBridge(
    input src_clk, dst_clk,
    input req_in, ack_out,
    output reg req_out, ack_in,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    reg [31:0] buf_reg;
    reg src_flag, dst_flag;
    
    always @(posedge src_clk) begin
        if (req_in && !ack_in) begin
            buf_reg <= data_in;
            src_flag <= ~src_flag;
            req_out <= 1;
        end
        if (ack_out) req_out <= 0;
    end
    
    always @(posedge dst_clk) begin
        if (req_out && (src_flag != dst_flag)) begin
            data_out <= buf_reg;
            dst_flag <= src_flag;
            ack_in <= 1;
        end else ack_in <= 0;
    end
endmodule