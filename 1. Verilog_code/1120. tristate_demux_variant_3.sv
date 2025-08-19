//SystemVerilog
module tristate_demux (
    input wire data,                     // Input data
    input wire [1:0] select,             // Selection control
    input wire output_enable,            // Output enable
    output wire [3:0] demux_bus          // Tristate output bus
);

    reg demux_bus_0_reg;
    reg demux_bus_1_reg;
    reg demux_bus_2_reg;
    reg demux_bus_3_reg;
    reg demux_bus_0_en;
    reg demux_bus_1_en;
    reg demux_bus_2_en;
    reg demux_bus_3_en;

    // Output enable logic for demux_bus_0
    always @(*) begin
        if (output_enable && (select == 2'b00)) begin
            demux_bus_0_reg = data;
            demux_bus_0_en = 1'b1;
        end else begin
            demux_bus_0_reg = 1'bz;
            demux_bus_0_en = 1'b0;
        end
    end

    // Output enable logic for demux_bus_1
    always @(*) begin
        if (output_enable && (select == 2'b01)) begin
            demux_bus_1_reg = data;
            demux_bus_1_en = 1'b1;
        end else begin
            demux_bus_1_reg = 1'bz;
            demux_bus_1_en = 1'b0;
        end
    end

    // Output enable logic for demux_bus_2
    always @(*) begin
        if (output_enable && (select == 2'b10)) begin
            demux_bus_2_reg = data;
            demux_bus_2_en = 1'b1;
        end else begin
            demux_bus_2_reg = 1'bz;
            demux_bus_2_en = 1'b0;
        end
    end

    // Output enable logic for demux_bus_3
    always @(*) begin
        if (output_enable && (select == 2'b11)) begin
            demux_bus_3_reg = data;
            demux_bus_3_en = 1'b1;
        end else begin
            demux_bus_3_reg = 1'bz;
            demux_bus_3_en = 1'b0;
        end
    end

    assign demux_bus[0] = demux_bus_0_en ? demux_bus_0_reg : 1'bz;
    assign demux_bus[1] = demux_bus_1_en ? demux_bus_1_reg : 1'bz;
    assign demux_bus[2] = demux_bus_2_en ? demux_bus_2_reg : 1'bz;
    assign demux_bus[3] = demux_bus_3_en ? demux_bus_3_reg : 1'bz;

endmodule