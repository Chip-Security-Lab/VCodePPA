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
    reg [WIDE-1:0] buffer;
    reg [$clog2(RATIO):0] count;
    reg [WIDE-1:0] next_buffer;
    reg [$clog2(RATIO):0] next_count;
    reg next_wide_valid;
    reg next_narrow_ready;
    reg [WIDE-1:0] next_wide_data;
    
    // Reset logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer <= 0;
            count <= 0;
            wide_valid <= 0;
            narrow_ready <= 1;
        end else if (enable) begin
            buffer <= next_buffer;
            count <= next_count;
            wide_valid <= next_wide_valid;
            narrow_ready <= next_narrow_ready;
            wide_data <= next_wide_data;
        end
    end
    
    // Next state logic for buffer and count
    always @(*) begin
        next_buffer = buffer;
        next_count = count;
        next_wide_data = wide_data;
        
        if (narrow_valid && narrow_ready) begin
            next_buffer = {buffer[WIDE-NARROW-1:0], narrow_data};
            next_count = count + 1;
            
            if (count == RATIO-1) begin
                next_wide_data = {narrow_data, buffer[WIDE-NARROW-1:0]};
            end
        end
    end
    
    // Next state logic for control signals
    always @(*) begin
        next_wide_valid = wide_valid;
        next_narrow_ready = narrow_ready;
        
        if (narrow_valid && narrow_ready) begin
            if (count == RATIO-1) begin
                next_wide_valid = 1;
                next_narrow_ready = 0;
            end
        end else if (wide_valid && wide_ready) begin
            next_wide_valid = 0;
            next_narrow_ready = 1;
        end
    end
endmodule