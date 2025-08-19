//SystemVerilog
// SystemVerilog
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
        if (req_in) begin
            if (!ack_in) begin
                buf_reg <= data_in;
                src_flag <= ~src_flag;
                req_out <= 1'b1;
            end
        end else if (ack_out) begin
            req_out <= 1'b0;
        end
    end

    always @(posedge dst_clk) begin
        ack_in <= req_out && (src_flag ^ dst_flag);
        if (ack_in) begin
            data_out <= buf_reg;
            dst_flag <= src_flag;
        end
    end
endmodule