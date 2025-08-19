//SystemVerilog
module pipo_rotate #(
    parameter WIDTH = 16
)(
    input wire i_clk,
    input wire i_rst,
    input wire i_load,
    input wire i_shift,
    input wire i_dir,
    input wire [WIDTH-1:0] i_data,
    output reg [WIDTH-1:0] o_data
);

    // Internal signal for next data value
    wire [WIDTH-1:0] rotated_data;
    wire [WIDTH-1:0] mux_shift_data;
    reg  [WIDTH-1:0] data_reg;

    // Combinational logic for rotation
    assign rotated_data = i_dir ? {data_reg[WIDTH-2:0], data_reg[WIDTH-1]} :
                                  {data_reg[0], data_reg[WIDTH-1:1]};

    // Mux for shift operation
    assign mux_shift_data = i_shift ? rotated_data : data_reg;

    // Register: data_reg is updated after the combination logic (forward retiming)
    always @(posedge i_clk or posedge i_rst) begin : data_reg_update
        if (i_rst) begin
            data_reg <= {WIDTH{1'b0}};
        end else if (i_load) begin
            data_reg <= i_data;
        end else begin
            data_reg <= mux_shift_data;
        end
    end

    // Register: output assignment, forward retimed to directly latch data_reg
    always @(posedge i_clk or posedge i_rst) begin : output_register
        if (i_rst) begin
            o_data <= {WIDTH{1'b0}};
        end else begin
            o_data <= data_reg;
        end
    end

endmodule