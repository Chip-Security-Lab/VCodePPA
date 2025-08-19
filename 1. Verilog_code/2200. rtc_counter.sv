module rtc_counter #(
    parameter WIDTH = 32
)(
    input wire clk_i,
    input wire rst_i,
    input wire en_i,
    output reg rollover_o,
    output wire [WIDTH-1:0] count_o
);
    reg [WIDTH-1:0] counter;
    
    assign count_o = counter;
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter <= {WIDTH{1'b0}};
            rollover_o <= 1'b0;
        end else if (en_i) begin
            if (&counter) begin
                counter <= {WIDTH{1'b0}};
                rollover_o <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                rollover_o <= 1'b0;
            end
        end
    end
endmodule