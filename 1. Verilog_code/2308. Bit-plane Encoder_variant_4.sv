//SystemVerilog
module bitplane_encoder #(
    parameter DEPTH = 8,
    parameter WIDTH = 8
)(
    input                  clk,
    input                  reset,
    input                  enable,
    input [WIDTH-1:0]      data_in,
    input                  data_valid,
    output reg             bit_out,
    output reg             bit_valid,
    output reg [2:0]       current_plane
);
    // Buffer registers for data storage
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    // Pointer register
    reg [$clog2(DEPTH)-1:0] ptr;
    // Pipelined control signals
    reg data_valid_r;
    reg enable_r;
    
    // Stage 1: Register control signals
    always @(posedge clk) begin
        if (reset) begin
            data_valid_r <= 0;
            enable_r <= 0;
        end else begin
            data_valid_r <= data_valid;
            enable_r <= enable;
        end
    end
    
    // Stage 2: Manage pointer reset
    always @(posedge clk) begin
        if (reset) begin
            ptr <= 0;
        end else if (enable_r && data_valid_r) begin
            ptr <= (ptr == DEPTH-1) ? 0 : ptr + 1;
        end else if (enable_r && !data_valid_r && ptr != DEPTH-1) begin
            ptr <= ptr + 1;
        end
    end
    
    // Stage 3: Manage buffer data storage
    always @(posedge clk) begin
        if (enable_r && data_valid_r) begin
            buffer[ptr] <= data_in;
        end
    end
    
    // Stage 4: Manage current_plane counter
    always @(posedge clk) begin
        if (reset) begin
            current_plane <= 0;
        end else if (enable_r && !data_valid_r && ptr == DEPTH-1) begin
            current_plane <= (current_plane == WIDTH-1) ? 0 : current_plane + 1;
        end
    end
    
    // Stage 5: Generate output bit and valid signal
    always @(posedge clk) begin
        if (reset) begin
            bit_valid <= 0;
            bit_out <= 0;
        end else if (!enable_r) begin
            bit_valid <= 0;
        end else if (!data_valid_r && ptr == 0) begin
            bit_out <= buffer[ptr][current_plane];
            bit_valid <= 1;
        end else begin
            bit_valid <= 0;
        end
    end
endmodule