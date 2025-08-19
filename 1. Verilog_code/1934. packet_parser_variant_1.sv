//SystemVerilog
module packet_parser #(parameter DW=32) (
    input  wire        clk,
    input  wire        valid,
    input  wire [DW-1:0] packet,
    output reg  [7:0]  header,
    output reg  [15:0] payload
);

    // Stage 1: Capture input packet when valid
    reg [DW-1:0] packet_stage1;
    reg          valid_stage1;

    always @(posedge clk) begin
        if (valid) begin
            packet_stage1 <= packet;
            valid_stage1  <= 1'b1;
        end else begin
            valid_stage1  <= 1'b0;
        end
    end

    // Stage 2: Extract fields from the registered packet
    reg [7:0]  header_stage2;
    reg [15:0] payload_stage2;
    reg        valid_stage2;

    always @(posedge clk) begin
        if (valid_stage1) begin
            header_stage2  <= packet_stage1[31:24];
            payload_stage2 <= packet_stage1[23:8];
            valid_stage2   <= 1'b1;
        end else begin
            valid_stage2   <= 1'b0;
        end
    end

    // Stage 3: Output stage (registered outputs)
    always @(posedge clk) begin
        if (valid_stage2) begin
            header  <= header_stage2;
            payload <= payload_stage2;
        end
    end

endmodule