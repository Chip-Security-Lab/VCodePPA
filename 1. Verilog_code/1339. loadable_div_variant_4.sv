//SystemVerilog
// Top level module
module loadable_div #(
    parameter W = 4
)(
    input wire clk,
    input wire load,
    input wire [W-1:0] div_val,
    output wire clk_out
);

    // Internal signals for connecting submodules
    wire [W-1:0] counter_value;
    wire counter_zero;
    wire [W-1:0] next_count;
    
    // Counter control submodule instance
    counter_control #(
        .WIDTH(W)
    ) counter_ctrl_inst (
        .clk(clk),
        .load(load),
        .div_val(div_val),
        .current_count(counter_value),
        .next_count(next_count)
    );
    
    // Counter register submodule instance
    counter_register #(
        .WIDTH(W)
    ) counter_reg_inst (
        .clk(clk),
        .next_count(next_count),
        .current_count(counter_value)
    );
    
    // Output generation submodule instance
    output_generator #(
        .WIDTH(W)
    ) output_gen_inst (
        .clk(clk),
        .load(load),
        .counter_value(counter_value),
        .clk_out(clk_out)
    );

endmodule

// Counter control logic submodule
module counter_control #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire load,
    input wire [WIDTH-1:0] div_val,
    input wire [WIDTH-1:0] current_count,
    output wire [WIDTH-1:0] next_count
);

    // Determine the next counter value based on load and current count
    assign next_count = load ? div_val : 
                       (current_count == 0) ? div_val : current_count - 1'b1;

endmodule

// Counter register submodule
module counter_register #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire [WIDTH-1:0] next_count,
    output reg [WIDTH-1:0] current_count
);

    // Update counter register on clock edge
    always @(posedge clk) begin
        current_count <= next_count;
    end

endmodule

// Output generator submodule
module output_generator #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire load,
    input wire [WIDTH-1:0] counter_value,
    output reg clk_out
);

    // Generate output clock signal
    always @(posedge clk) begin
        if (load) begin
            clk_out <= 1'b1;
        end else begin
            clk_out <= (counter_value != 0);
        end
    end

endmodule