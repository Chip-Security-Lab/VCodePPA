//SystemVerilog
// Top-level barrel shifter module using explicit multiplexer-based structure
module log_barrel_shifter #(parameter WIDTH=32) (
    input  [WIDTH-1:0] in_data,
    input  [$clog2(WIDTH)-1:0] shift,
    output [WIDTH-1:0] out_data
);

    wire [WIDTH-1:0] stage_wire_0;
    wire [WIDTH-1:0] stage_wire_1;
    wire [WIDTH-1:0] stage_wire_2;
    wire [WIDTH-1:0] stage_wire_3;
    wire [WIDTH-1:0] stage_wire_4;
    wire [WIDTH-1:0] stage_wire_5;
    
    // Support up to 32-bit width, so up to 5 shift stages (2^5 = 32)
    // For other widths, adjust number of stages accordingly

    assign stage_wire_0 = in_data;

    // Stage 0: Shift by 1 if shift[0] is set
    genvar k0;
    generate
        for (k0 = 0; k0 < WIDTH; k0 = k0 + 1) begin : gen_mux_stage0
            assign stage_wire_1[k0] = shift[0] ? 
                ((k0 >= 1) ? stage_wire_0[k0-1] : 1'b0) :
                stage_wire_0[k0];
        end
    endgenerate

    // Stage 1: Shift by 2 if shift[1] is set
    genvar k1;
    generate
        for (k1 = 0; k1 < WIDTH; k1 = k1 + 1) begin : gen_mux_stage1
            assign stage_wire_2[k1] = shift[1] ? 
                ((k1 >= 2) ? stage_wire_1[k1-2] : 1'b0) :
                stage_wire_1[k1];
        end
    endgenerate

    // Stage 2: Shift by 4 if shift[2] is set
    genvar k2;
    generate
        for (k2 = 0; k2 < WIDTH; k2 = k2 + 1) begin : gen_mux_stage2
            assign stage_wire_3[k2] = shift[2] ? 
                ((k2 >= 4) ? stage_wire_2[k2-4] : 1'b0) :
                stage_wire_2[k2];
        end
    endgenerate

    // Stage 3: Shift by 8 if shift[3] is set
    genvar k3;
    generate
        for (k3 = 0; k3 < WIDTH; k3 = k3 + 1) begin : gen_mux_stage3
            assign stage_wire_4[k3] = shift[3] ? 
                ((k3 >= 8) ? stage_wire_3[k3-8] : 1'b0) :
                stage_wire_3[k3];
        end
    endgenerate

    // Stage 4: Shift by 16 if shift[4] is set (for WIDTH up to 32)
    genvar k4;
    generate
        for (k4 = 0; k4 < WIDTH; k4 = k4 + 1) begin : gen_mux_stage4
            assign stage_wire_5[k4] = shift[4] ? 
                ((k4 >= 16) ? stage_wire_4[k4-16] : 1'b0) :
                stage_wire_4[k4];
        end
    endgenerate

    // Assign output according to WIDTH
    generate
        if ($clog2(WIDTH) == 1) begin
            assign out_data = stage_wire_1;
        end else if ($clog2(WIDTH) == 2) begin
            assign out_data = stage_wire_2;
        end else if ($clog2(WIDTH) == 3) begin
            assign out_data = stage_wire_3;
        end else if ($clog2(WIDTH) == 4) begin
            assign out_data = stage_wire_4;
        end else begin
            assign out_data = stage_wire_5;
        end
    endgenerate

endmodule