//SystemVerilog
module w2n_bridge #(parameter WIDE=32, NARROW=8) (
    input clk, rst_n,
    input [WIDE-1:0] wide_data,
    input wide_valid,
    output reg wide_ready,
    output reg [NARROW-1:0] narrow_data,
    output reg narrow_valid,
    input narrow_ready
);
    localparam RATIO = WIDE/NARROW;
    reg [WIDE-1:0] buffer;
    reg [$clog2(RATIO):0] count;
    wire count_is_zero;
    wire count_is_last;
    wire can_accept_wide;
    wire can_send_narrow;
    
    assign count_is_zero = (count == 0);
    assign count_is_last = (count == RATIO-1);
    assign can_accept_wide = wide_valid && wide_ready && count_is_zero;
    assign can_send_narrow = narrow_valid && narrow_ready;
    
    // Buffer control
    always @(posedge clk) begin
        if (!rst_n) begin
            buffer <= 0;
        end else if (can_accept_wide) begin
            buffer <= wide_data;
        end
    end
    
    // Count control
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= 0;
        end else if (can_accept_wide) begin
            count <= 1;
        end else if (can_send_narrow) begin
            if (count < RATIO) begin
                count <= count + 1;
            end
            if (count_is_last) begin
                count <= 0;
            end
        end
    end
    
    // Narrow data output
    always @(posedge clk) begin
        if (!rst_n) begin
            narrow_data <= 0;
        end else if (can_accept_wide) begin
            narrow_data <= wide_data[NARROW-1:0];
        end else if (can_send_narrow && count < RATIO) begin
            narrow_data <= buffer[count*NARROW +: NARROW];
        end
    end
    
    // Valid/Ready control
    always @(posedge clk) begin
        if (!rst_n) begin
            narrow_valid <= 0;
            wide_ready <= 1;
        end else if (can_accept_wide) begin
            narrow_valid <= 1;
            wide_ready <= 0;
        end else if (can_send_narrow && count_is_last) begin
            narrow_valid <= 0;
            wide_ready <= 1;
        end
    end
endmodule