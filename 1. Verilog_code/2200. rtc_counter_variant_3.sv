//SystemVerilog
module rtc_counter #(
    parameter WIDTH = 32
)(
    input wire clk_i,
    input wire rst_i,
    input wire en_i,
    output reg rollover_o,
    output wire [WIDTH-1:0] count_o
);
    // Main counter register with direct output assignment
    reg [WIDTH-1:0] counter;
    assign count_o = counter;
    
    // Optimize max value detection by checking only when needed
    wire counter_at_max = &counter;
    
    // Main counter logic with simplified rollover detection
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter <= {WIDTH{1'b0}};
            rollover_o <= 1'b0;
        end else if (en_i) begin
            if (counter_at_max) begin
                counter <= {WIDTH{1'b0}};
                rollover_o <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                rollover_o <= 1'b0;
            end
        end
    end
endmodule