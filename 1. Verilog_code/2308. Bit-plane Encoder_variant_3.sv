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
    // Data storage
    reg [WIDTH-1:0] buffer [0:DEPTH-1];
    reg [$clog2(DEPTH)-1:0] ptr_stage1, ptr_stage2, ptr_stage3;
    
    // Pipeline control signals
    reg data_valid_stage1, data_valid_stage2;
    reg enable_stage1, enable_stage2, enable_stage3;
    reg [WIDTH-1:0] data_in_stage1;
    
    // Pipeline stage signals
    reg [2:0] current_plane_stage1, current_plane_stage2;
    reg bit_valid_stage2;
    reg bit_out_stage2;
    
    // Stage 1: Input processing and buffer write
    always @(posedge clk) begin
        if (reset) begin
            data_valid_stage1 <= 0;
            enable_stage1 <= 0;
            data_in_stage1 <= 0;
            ptr_stage1 <= 0;
            current_plane_stage1 <= 0;
        end else begin
            data_valid_stage1 <= data_valid;
            enable_stage1 <= enable;
            data_in_stage1 <= data_in;
            
            if (enable_stage1 && data_valid_stage1) begin
                buffer[ptr_stage1] <= data_in_stage1;
                ptr_stage1 <= (ptr_stage1 == DEPTH-1) ? 0 : ptr_stage1 + 1;
            end else if (enable_stage1 && !data_valid_stage1) begin
                ptr_stage1 <= (ptr_stage1 == DEPTH-1) ? 0 : ptr_stage1 + 1;
                if (ptr_stage1 == DEPTH-1) begin
                    current_plane_stage1 <= (current_plane_stage1 == WIDTH-1) ? 0 : current_plane_stage1 + 1;
                end
            end
        end
    end
    
    // Stage 2: Data fetch and bit extraction
    always @(posedge clk) begin
        if (reset) begin
            ptr_stage2 <= 0;
            current_plane_stage2 <= 0;
            enable_stage2 <= 0;
            data_valid_stage2 <= 0;
            bit_valid_stage2 <= 0;
            bit_out_stage2 <= 0;
        end else begin
            ptr_stage2 <= ptr_stage1;
            current_plane_stage2 <= current_plane_stage1;
            enable_stage2 <= enable_stage1;
            data_valid_stage2 <= data_valid_stage1;
            
            // Process data - extract bit from current sample and bitplane
            if (enable_stage1 && !data_valid_stage1) begin
                bit_out_stage2 <= buffer[ptr_stage1][current_plane_stage1];
                bit_valid_stage2 <= 1;
            end else begin
                bit_valid_stage2 <= 0;
            end
        end
    end
    
    // Stage 3: Output
    always @(posedge clk) begin
        if (reset) begin
            bit_out <= 0;
            bit_valid <= 0;
            current_plane <= 0;
            enable_stage3 <= 0;
            ptr_stage3 <= 0;
        end else begin
            enable_stage3 <= enable_stage2;
            ptr_stage3 <= ptr_stage2;
            
            // Forward outputs
            bit_out <= bit_out_stage2;
            bit_valid <= bit_valid_stage2 && enable_stage2;
            current_plane <= current_plane_stage2;
        end
    end
endmodule