//SystemVerilog
// Top-level module - Clock Divider with Pulse Generation
module del_pulse_div #(parameter N=3) (
    input  wire clk,
    input  wire rst,
    output wire clk_out
);
    // Internal signals for connecting submodules
    wire counter_reset;
    wire [2:0] count_value;

    // Instantiate counter submodule
    counter_module #(
        .COUNT_WIDTH(3),
        .MAX_COUNT(N-1)
    ) counter_inst (
        .clk(clk),
        .rst(rst),
        .enable(1'b1),
        .count_value(count_value),
        .terminal_count(counter_reset)
    );

    // Instantiate toggle flip-flop submodule
    toggle_ff_module toggle_inst (
        .clk(clk),
        .rst(rst),
        .toggle_enable(counter_reset),
        .q(clk_out)
    );

endmodule

// Counter submodule with separated combinational and sequential logic
module counter_module #(
    parameter COUNT_WIDTH = 3,
    parameter MAX_COUNT = 2
) (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  [COUNT_WIDTH-1:0] count_value,
    output wire terminal_count
);
    // Combinational logic signals
    wire [COUNT_WIDTH-1:0] next_count;
    wire count_at_max;
    
    // Combinational logic block for terminal count detection
    assign count_at_max = (count_value == MAX_COUNT);
    assign terminal_count = count_at_max;
    
    // Combinational logic block for next counter value calculation
    assign next_count = (count_at_max) ? {COUNT_WIDTH{1'b0}} : 
                        (enable) ? count_value + 1'b1 : 
                        count_value;
    
    // Sequential logic block - register updates only
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_value <= {COUNT_WIDTH{1'b0}};
        end else begin
            count_value <= next_count;
        end
    end
endmodule

// Toggle flip-flop submodule with separated combinational and sequential logic
module toggle_ff_module (
    input  wire clk,
    input  wire rst,
    input  wire toggle_enable,
    output reg  q
);
    // Combinational logic signal
    wire next_q;
    
    // Combinational logic block for next q calculation
    assign next_q = toggle_enable ? ~q : q;
    
    // Sequential logic block - register updates only
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= 1'b0;
        end else begin
            q <= next_q;
        end
    end
endmodule