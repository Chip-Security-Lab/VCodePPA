//SystemVerilog
module compare_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update_main,
    input wire update_shadow,
    output wire [WIDTH-1:0] main_data,
    output wire [WIDTH-1:0] shadow_data,
    output wire data_match
);

    // Submodule for main register update
    wire [WIDTH-1:0] main_data_out;
    main_register #(.WIDTH(WIDTH)) u_main_register (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .update(update_main),
        .data_out(main_data_out)
    );

    // Submodule for shadow register update
    wire [WIDTH-1:0] shadow_data_out;
    shadow_register #(.WIDTH(WIDTH)) u_shadow_register (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .update(update_shadow),
        .data_out(shadow_data_out)
    );

    // Submodule for comparison logic
    wire match;
    comparison_logic #(.WIDTH(WIDTH)) u_comparison_logic (
        .main_data(main_data_out),
        .shadow_data(shadow_data_out),
        .data_match(match)
    );

    assign main_data = main_data_out;
    assign shadow_data = shadow_data_out;
    assign data_match = match;

endmodule

// Submodule for main register
module main_register #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
        end else if (update) begin
            data_out <= data_in;
        end
    end
endmodule

// Submodule for shadow register
module shadow_register #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
        end else if (update) begin
            data_out <= data_in;
        end
    end
endmodule

// Submodule for comparison logic
module comparison_logic #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] main_data,
    input wire [WIDTH-1:0] shadow_data,
    output reg data_match
);
    always @(*) begin
        data_match = (main_data == shadow_data);
    end
endmodule