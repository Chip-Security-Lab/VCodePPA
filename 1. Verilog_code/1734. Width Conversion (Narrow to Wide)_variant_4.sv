//SystemVerilog
module n2w_bridge #(parameter NARROW=8, WIDE=32) (
    input clk, rst_n, enable,
    input [NARROW-1:0] narrow_data,
    input narrow_valid,
    output reg narrow_ready,
    output reg [WIDE-1:0] wide_data,
    output reg wide_valid,
    input wide_ready
);
    localparam RATIO = WIDE/NARROW;
    localparam COUNT_WIDTH = $clog2(RATIO);
    
    reg [WIDE-1:0] buffer;
    reg [COUNT_WIDTH:0] count;
    reg [COUNT_WIDTH:0] next_count;
    reg [WIDE-1:0] next_buffer;
    reg next_wide_valid;
    reg next_narrow_ready;
    reg [WIDE-1:0] next_wide_data;
    
    // Pipeline registers
    reg [WIDE-1:0] buffer_pipe;
    reg [COUNT_WIDTH:0] count_pipe;
    reg wide_valid_pipe;
    reg narrow_ready_pipe;
    reg [WIDE-1:0] wide_data_pipe;
    
    // Pre-compute control signals
    wire count_full = (count == RATIO-1);
    wire can_accept_narrow = narrow_valid && narrow_ready;
    wire can_transfer_wide = wide_valid && wide_ready;
    
    // Stage 1: Buffer and count update
    always @(*) begin
        next_count = count;
        next_buffer = buffer;
        
        if (enable && can_accept_narrow) begin
            next_buffer = {buffer[WIDE-NARROW-1:0], narrow_data};
            next_count = count + 1;
        end
    end
    
    // Stage 2: Control and data transfer
    always @(*) begin
        next_wide_valid = wide_valid;
        next_narrow_ready = narrow_ready;
        next_wide_data = wide_data;
        
        if (enable) begin
            if (count_full && can_accept_narrow) begin
                next_wide_data = {narrow_data, buffer[WIDE-NARROW-1:0]};
                next_wide_valid = 1'b1;
                next_narrow_ready = 1'b0;
            end else if (can_transfer_wide) begin
                next_wide_valid = 1'b0;
                next_narrow_ready = 1'b1;
            end
        end
    end
    
    // Sequential logic with pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer <= 0;
            count <= 0;
            wide_valid <= 0;
            narrow_ready <= 1;
            wide_data <= 0;
            buffer_pipe <= 0;
            count_pipe <= 0;
            wide_valid_pipe <= 0;
            narrow_ready_pipe <= 1;
            wide_data_pipe <= 0;
        end else begin
            // Pipeline stage 1
            buffer_pipe <= next_buffer;
            count_pipe <= next_count;
            
            // Pipeline stage 2
            buffer <= buffer_pipe;
            count <= count_pipe;
            wide_valid <= next_wide_valid;
            narrow_ready <= next_narrow_ready;
            wide_data <= next_wide_data;
        end
    end
endmodule