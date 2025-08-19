//SystemVerilog
module handshake_sync #(parameter DW=32) (
    input  wire              src_clk,
    input  wire              dst_clk,
    input  wire              rst,
    input  wire [DW-1:0]     data_in,
    output reg  [DW-1:0]     data_out,
    output reg               ack
);

    wire                     req_sync_dst;
    wire                     ack_sync_src;
    reg                      req_flag_src;
    reg                      ack_flag_dst;

    // Source clock domain: Generate request and capture ack
    always @(posedge src_clk or posedge rst) begin
        if (rst) begin
            req_flag_src <= 1'b0;
            data_out     <= {DW{1'b0}};
        end else begin
            if (!req_flag_src && !ack_sync_src) begin
                data_out     <= data_in;
                req_flag_src <= 1'b1;
            end else if (ack_sync_src) begin
                req_flag_src <= 1'b0;
            end
        end
    end

    // Synchronizer for req_flag_src from src_clk to dst_clk
    sync_2ff #(
        .WIDTH(1)
    ) u_req_sync (
        .clk    (dst_clk),
        .rst    (rst),
        .din    (req_flag_src),
        .dout   (req_sync_dst)
    );

    // Destination clock domain: Latch ack and clear request
    always @(posedge dst_clk or posedge rst) begin
        if (rst) begin
            ack_flag_dst <= 1'b0;
            ack          <= 1'b0;
        end else begin
            if (req_sync_dst) begin
                ack_flag_dst <= 1'b1;
            end else begin
                ack_flag_dst <= 1'b0;
            end
            ack <= ack_flag_dst;
        end
    end

    // Synchronizer for ack_flag_dst from dst_clk to src_clk
    sync_2ff #(
        .WIDTH(1)
    ) u_ack_sync (
        .clk    (src_clk),
        .rst    (rst),
        .din    (ack_flag_dst),
        .dout   (ack_sync_src)
    );

endmodule

// 2-stage generic synchronizer module
module sync_2ff #(
    parameter WIDTH = 1
) (
    input  wire              clk,
    input  wire              rst,
    input  wire [WIDTH-1:0]  din,
    output wire [WIDTH-1:0]  dout
);
    reg [WIDTH-1:0] sync_ff1, sync_ff2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_ff1 <= {WIDTH{1'b0}};
            sync_ff2 <= {WIDTH{1'b0}};
        end else begin
            sync_ff1 <= din;
            sync_ff2 <= sync_ff1;
        end
    end

    assign dout = sync_ff2;
endmodule