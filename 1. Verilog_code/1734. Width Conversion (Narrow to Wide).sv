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
    
    always @(posedge clk) begin
        if (!rst_n) begin
            buffer <= 0; count <= 0; wide_valid <= 0; narrow_ready <= 1;
        end else if (enable) begin
            if (narrow_valid && narrow_ready) begin
                buffer <= {buffer[WIDE-NARROW-1:0], narrow_data};
                count <= count + 1;
                if (count == RATIO-1) begin
                    wide_data <= {narrow_data, buffer[WIDE-NARROW-1:0]};
                    wide_valid <= 1;
                    narrow_ready <= 0;
                    count <= 0;
                end
            end else if (wide_valid && wide_ready) begin
                wide_valid <= 0;
                narrow_ready <= 1;
            end
        end
    end
endmodule