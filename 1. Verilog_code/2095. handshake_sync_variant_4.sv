//SystemVerilog
module handshake_sync_pipelined #(
    parameter DW = 32
) (
    input                   src_clk,
    input                   dst_clk,
    input                   rst,
    input       [DW-1:0]    data_in,
    output reg  [DW-1:0]    data_out,
    output reg              ack
);

// Stage 1: Source domain, capture data and request
reg         req_stage1_reg;
reg [DW-1:0] data_stage1_reg;
reg         valid_stage1_reg;

always @(posedge src_clk or posedge rst) begin
    if (rst) begin
        req_stage1_reg   <= 1'b0;
        data_stage1_reg  <= {DW{1'b0}};
        valid_stage1_reg <= 1'b0;
    end else begin
        if (!req_stage1_reg && !valid_stage1_reg) begin
            data_stage1_reg  <= data_in;
            req_stage1_reg   <= 1'b1;
            valid_stage1_reg <= 1'b1;
        end else if (req_stage1_reg && valid_stage1_reg) begin
            req_stage1_reg   <= req_stage1_reg;
            data_stage1_reg  <= data_stage1_reg;
            valid_stage1_reg <= valid_stage1_reg;
        end else if (!req_stage1_reg && valid_stage1_reg) begin
            req_stage1_reg <= 1'b1;
        end
    end
end

// Buffering src_clk for high fanout
reg src_clk_buf1, src_clk_buf2;
always @(posedge src_clk or posedge rst) begin
    if (rst) begin
        src_clk_buf1 <= 1'b0;
        src_clk_buf2 <= 1'b0;
    end else begin
        src_clk_buf1 <= 1'b1;
        src_clk_buf2 <= src_clk_buf1;
    end
end
wire src_clk_buffered = src_clk_buf2;

// Buffering dst_clk for high fanout
reg dst_clk_buf1, dst_clk_buf2;
always @(posedge dst_clk or posedge rst) begin
    if (rst) begin
        dst_clk_buf1 <= 1'b0;
        dst_clk_buf2 <= 1'b0;
    end else begin
        dst_clk_buf1 <= 1'b1;
        dst_clk_buf2 <= dst_clk_buf1;
    end
end
wire dst_clk_buffered = dst_clk_buf2;

// Buffering req_stage1 for high fanout
reg req_stage1_buf1, req_stage1_buf2;
always @(posedge src_clk or posedge rst) begin
    if (rst) begin
        req_stage1_buf1 <= 1'b0;
        req_stage1_buf2 <= 1'b0;
    end else begin
        req_stage1_buf1 <= req_stage1_reg;
        req_stage1_buf2 <= req_stage1_buf1;
    end
end
wire req_stage1_buffered = req_stage1_buf2;

// Buffering data_stage1 for high fanout
reg [DW-1:0] data_stage1_buf1, data_stage1_buf2;
always @(posedge src_clk or posedge rst) begin
    if (rst) begin
        data_stage1_buf1 <= {DW{1'b0}};
        data_stage1_buf2 <= {DW{1'b0}};
    end else begin
        data_stage1_buf1 <= data_stage1_reg;
        data_stage1_buf2 <= data_stage1_buf1;
    end
end
wire [DW-1:0] data_stage1_buffered = data_stage1_buf2;

// Buffering ack for high fanout
reg ack_buf1, ack_buf2;
always @(posedge dst_clk or posedge rst) begin
    if (rst) begin
        ack_buf1 <= 1'b0;
        ack_buf2 <= 1'b0;
    end else begin
        ack_buf1 <= ack;
        ack_buf2 <= ack_buf1;
    end
end
wire ack_buffered = ack_buf2;

// Stage 2: Synchronize request to destination clock domain (2-stage synchronizer)
reg req_sync_stage1;
reg req_sync_stage2;
reg valid_stage2;

always @(posedge dst_clk or posedge rst) begin
    if (rst) begin
        req_sync_stage1 <= 1'b0;
        req_sync_stage2 <= 1'b0;
        valid_stage2    <= 1'b0;
    end else begin
        req_sync_stage1 <= req_stage1_buffered;
        req_sync_stage2 <= req_sync_stage1;
        valid_stage2    <= req_sync_stage2;
    end
end

// Subtractor: 8-bit conditional inversion subtractor (DW==8) module
module subtractor_conditional_invert_8bit (
    input  [7:0] minuend,
    input  [7:0] subtrahend,
    output [7:0] difference
);
    wire [7:0] subtrahend_inverted;
    wire [7:0] sum;
    wire       carry_out;

    assign subtrahend_inverted = ~subtrahend;
    assign {carry_out, sum} = {1'b0, minuend} + {1'b0, subtrahend_inverted} + 9'd1;
    assign difference = sum;
endmodule

// Stage 3: Destination domain, capture data and generate ack
reg [DW-1:0] data_stage3_reg;
reg          ack_stage3_reg;
reg          valid_stage3_reg;

// Only apply conditional invert subtractor if DW==8, otherwise default assign
wire [DW-1:0] subtractor_result;
generate
    if (DW == 8) begin : gen_conditional_invert_subtractor
        reg  [7:0] minuend_reg;
        reg  [7:0] subtrahend_reg;
        wire [7:0] difference_wire;

        subtractor_conditional_invert_8bit u_subtractor_conditional_invert_8bit (
            .minuend     (minuend_reg),
            .subtrahend  (subtrahend_reg),
            .difference  (difference_wire)
        );

        always @(*) begin
            minuend_reg    = data_stage1_buffered[7:0];
            subtrahend_reg = 8'd0; // Replace with actual subtrahend if needed
        end

        assign subtractor_result = {24'd0, difference_wire};
    end else begin : gen_default_subtractor
        assign subtractor_result = data_stage1_buffered;
    end
endgenerate

always @(posedge dst_clk or posedge rst) begin
    if (rst) begin
        data_stage3_reg   <= {DW{1'b0}};
        ack_stage3_reg    <= 1'b0;
        valid_stage3_reg  <= 1'b0;
    end else begin
        if (valid_stage2 && !valid_stage3_reg) begin
            data_stage3_reg  <= subtractor_result;
            ack_stage3_reg   <= 1'b1;
            valid_stage3_reg <= 1'b1;
        end else if (valid_stage3_reg) begin
            ack_stage3_reg   <= 1'b0;
            valid_stage3_reg <= 1'b0;
        end
    end
end

// Stage 4: Synchronize ack back to source clock domain (2-stage synchronizer)
reg ack_stage3_buf1, ack_stage3_buf2;
always @(posedge dst_clk or posedge rst) begin
    if (rst) begin
        ack_stage3_buf1 <= 1'b0;
        ack_stage3_buf2 <= 1'b0;
    end else begin
        ack_stage3_buf1 <= ack_stage3_reg;
        ack_stage3_buf2 <= ack_stage3_buf1;
    end
end
wire ack_stage3_buffered = ack_stage3_buf2;

reg ack_sync_stage1;
reg ack_sync_stage2;
reg ack_stage4_reg;

always @(posedge src_clk or posedge rst) begin
    if (rst) begin
        ack_sync_stage1 <= 1'b0;
        ack_sync_stage2 <= 1'b0;
        ack_stage4_reg  <= 1'b0;
    end else begin
        ack_sync_stage1 <= ack_stage3_buffered;
        ack_sync_stage2 <= ack_sync_stage1;
        ack_stage4_reg  <= ack_sync_stage2;
    end
end

// Output logic and handshake control
always @(posedge src_clk or posedge rst) begin
    if (rst) begin
        req_stage1_reg   <= 1'b0;
        valid_stage1_reg <= 1'b0;
    end else begin
        if (ack_stage4_reg && req_stage1_reg) begin
            req_stage1_reg   <= 1'b0;
            valid_stage1_reg <= 1'b0;
        end
    end
end

always @(posedge dst_clk or posedge rst) begin
    if (rst) begin
        data_out <= {DW{1'b0}};
        ack     <= 1'b0;
    end else begin
        if (valid_stage3_reg) begin
            data_out <= data_stage3_reg;
            ack      <= ack_stage3_reg;
        end else begin
            ack      <= 1'b0;
        end
    end
end

endmodule