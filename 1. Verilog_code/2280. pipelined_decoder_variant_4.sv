//SystemVerilog
// Module: pipelined_decoder_top
// 顶层模块，实例化并连接各个子模块
module pipelined_decoder(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] addr_in,
    output wire [15:0] decode_out
);
    // Internal connection signals
    wire [3:0] addr_stage1;
    wire [3:0] addr_stage2;
    wire [3:0] addr_stage3;
    wire [7:0] decode_stage3_lower;
    wire [7:0] decode_stage3_upper;
    
    // Stage 1: Address input capture module
    addr_capture_stage stage1 (
        .clk      (clk),
        .rst_n    (rst_n),
        .addr_in  (addr_in),
        .addr_out (addr_stage1)
    );
    
    // Stage 2: Address propagation module
    addr_propagation_stage stage2 (
        .clk      (clk),
        .rst_n    (rst_n),
        .addr_in  (addr_stage1),
        .addr_out (addr_stage2)
    );
    
    // Stage 3: Address final stage module
    addr_propagation_stage stage3 (
        .clk      (clk),
        .rst_n    (rst_n),
        .addr_in  (addr_stage2),
        .addr_out (addr_stage3)
    );
    
    // Stage 4: Decode logic module
    decode_logic_stage stage4 (
        .clk           (clk),
        .rst_n         (rst_n),
        .addr_in       (addr_stage3),
        .decode_lower  (decode_stage3_lower),
        .decode_upper  (decode_stage3_upper)
    );
    
    // Stage 5: Output combining module
    output_combine_stage stage5 (
        .clk           (clk),
        .rst_n         (rst_n),
        .decode_lower  (decode_stage3_lower),
        .decode_upper  (decode_stage3_upper),
        .decode_out    (decode_out)
    );
    
endmodule

// Module: addr_capture_stage
// Captures input address and registers it
module addr_capture_stage #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [ADDR_WIDTH-1:0] addr_in,
    output reg  [ADDR_WIDTH-1:0] addr_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= {ADDR_WIDTH{1'b0}};
        end else begin
            addr_out <= addr_in;
        end
    end
    
endmodule

// Module: addr_propagation_stage
// Propagates address through pipeline
module addr_propagation_stage #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [ADDR_WIDTH-1:0] addr_in,
    output reg  [ADDR_WIDTH-1:0] addr_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= {ADDR_WIDTH{1'b0}};
        end else begin
            addr_out <= addr_in;
        end
    end
    
endmodule

// Module: decode_logic_stage
// Performs address decoding into lower and upper parts
module decode_logic_stage #(
    parameter ADDR_WIDTH = 4,
    parameter OUT_WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [ADDR_WIDTH-1:0] addr_in,
    output reg  [OUT_WIDTH-1:0] decode_lower,
    output reg  [OUT_WIDTH-1:0] decode_upper
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_lower <= {OUT_WIDTH{1'b0}};
            decode_upper <= {OUT_WIDTH{1'b0}};
        end else begin
            // Lower bits decoding (when addr_in[3] is 0)
            decode_lower <= (addr_in[3] == 1'b0) ? (1'b1 << addr_in[2:0]) : {OUT_WIDTH{1'b0}};
            // Upper bits decoding (when addr_in[3] is 1)
            decode_upper <= (addr_in[3] == 1'b1) ? (1'b1 << addr_in[2:0]) : {OUT_WIDTH{1'b0}};
        end
    end
    
endmodule

// Module: output_combine_stage
// Combines lower and upper decode results into final output
module output_combine_stage #(
    parameter HALF_WIDTH = 8,
    parameter FULL_WIDTH = 16
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [HALF_WIDTH-1:0]  decode_lower,
    input  wire [HALF_WIDTH-1:0]  decode_upper,
    output reg  [FULL_WIDTH-1:0]  decode_out
);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_out <= {FULL_WIDTH{1'b0}};
        end else begin
            decode_out <= {decode_upper, decode_lower};
        end
    end
    
endmodule