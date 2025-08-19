//SystemVerilog
module default_case_mux_valid_ready (
    input  wire        clk,                  // Clock for pipelining
    input  wire        rst_n,                // Active-low reset

    // Valid-Ready handshake for input
    input  wire        in_valid,             // Input data valid
    output wire        in_ready,             // Input data ready

    input  wire [2:0]  channel_sel,          // Channel selector
    input  wire [15:0] ch0, 
    input  wire [15:0] ch1, 
    input  wire [15:0] ch2, 
    input  wire [15:0] ch3, 
    input  wire [15:0] ch4, 

    // Valid-Ready handshake for output
    output reg         out_valid,            // Output data valid
    input  wire        out_ready,            // Output data ready

    output reg  [15:0] selected              // Selected output, pipelined
);

// Forward register retiming: move pipeline registers after the mux

// Stage 1: Input valid capture only
reg        valid_stage1;

// Stage 2: Multiplexing logic after retiming
reg [15:0] mux_out_stage2;
reg        valid_stage2;
reg [2:0]  sel_stage2;

// Stage 3: Output register for timing closure
reg [15:0] selected_stage3;
reg        valid_stage3;

// Input ready: can accept new data if stage1 is ready (i.e., no bubble in pipeline)
assign in_ready = !valid_stage1 || (valid_stage1 && (!valid_stage2 || (valid_stage2 && (!valid_stage3 || (valid_stage3 && out_ready)))));

// Stage 1: Capture only the valid signal on handshake
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_stage1 <= 1'b0;
    end else if (in_valid && in_ready) begin
        valid_stage1 <= 1'b1;
    end else if (in_ready) begin
        valid_stage1 <= 1'b0;
    end
end

// Stage 2: Multiplexing logic with valid propagation and selector pipelining
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mux_out_stage2 <= 16'h0000;
        sel_stage2     <= 3'b000;
        valid_stage2   <= 1'b0;
    end else if ((valid_stage1 && (!valid_stage2 || (valid_stage2 && (!valid_stage3 || (valid_stage3 && out_ready)))))) begin
        sel_stage2 <= channel_sel;
        case (channel_sel)
            3'b000: mux_out_stage2 <= ch0;
            3'b001: mux_out_stage2 <= ch1;
            3'b010: mux_out_stage2 <= ch2;
            3'b011: mux_out_stage2 <= ch3;
            3'b100: mux_out_stage2 <= ch4;
            default: mux_out_stage2 <= 16'h0000;
        endcase
        valid_stage2 <= valid_stage1;
    end else if (valid_stage2 && (!valid_stage3 || (valid_stage3 && out_ready))) begin
        valid_stage2 <= 1'b0;
    end
end

// Stage 3: Output register for timing closure with valid propagation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        selected_stage3 <= 16'h0000;
        valid_stage3    <= 1'b0;
    end else if (valid_stage2 && (!valid_stage3 || (valid_stage3 && out_ready))) begin
        selected_stage3 <= mux_out_stage2;
        valid_stage3    <= valid_stage2;
    end else if (valid_stage3 && out_ready) begin
        valid_stage3 <= 1'b0;
    end
end

// Output assignments
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        selected  <= 16'h0000;
        out_valid <= 1'b0;
    end else if (valid_stage3 && out_ready) begin
        selected  <= selected_stage3;
        out_valid <= valid_stage3;
    end else if (out_valid && out_ready) begin
        out_valid <= 1'b0;
    end
end

endmodule