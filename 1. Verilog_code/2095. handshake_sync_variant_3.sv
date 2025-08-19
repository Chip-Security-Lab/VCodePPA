//SystemVerilog
module handshake_sync #(parameter DW=32) (
    input  wire            src_clk,
    input  wire            dst_clk,
    input  wire            rst,
    input  wire [DW-1:0]   data_in,
    output reg  [DW-1:0]   data_out,
    output reg             ack
);

    reg req_src, req_src_d;
    reg req_dst, req_dst_d;

    reg ack_dst, ack_dst_d;
    reg ack_src, ack_src_d;

    reg [DW-1:0] data_latch;

    // Source domain: generate request and capture data (move data_out reg backward)
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            req_src   <= 1'b0;
            req_src_d <= 1'b0;
            ack_src   <= 1'b0;
            ack_src_d <= 1'b0;
            data_latch <= {DW{1'b0}};
        end else begin
            ack_src_d <= ack_dst;
            ack_src   <= ack_src_d;
            if (~req_src && ~ack_src) begin
                data_latch <= data_in;
                req_src  <= 1'b1;
            end else if (req_src && ack_src) begin
                req_src <= 1'b0;
            end
        end
    end

    // Synchronize req to destination domain
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            req_dst_d <= 1'b0;
            req_dst   <= 1'b0;
        end else begin
            req_dst_d <= req_src;
            req_dst   <= req_dst_d;
        end
    end

    // Destination domain: generate ack and move data_out reg backward
    reg [DW-1:0] data_dst_reg;
    reg [DW-1:0] data_dst_reg_d;

    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            ack_dst   <= 1'b0;
            ack_dst_d <= 1'b0;
            ack       <= 1'b0;
            data_dst_reg   <= {DW{1'b0}};
            data_dst_reg_d <= {DW{1'b0}};
        end else begin
            if (req_dst && ~ack_dst) begin
                data_dst_reg <= data_latch;
                ack_dst <= 1'b1;
            end else if (~req_dst) begin
                ack_dst <= 1'b0;
            end
            data_dst_reg_d <= data_dst_reg;
            ack_dst_d <= ack_dst;
            ack       <= ack_dst_d;
        end
    end

    // Move data_out reg to output domain (after data_dst_reg_d)
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            data_out <= {DW{1'b0}};
        end else begin
            data_out <= data_dst_reg_d;
        end
    end

endmodule