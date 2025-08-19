//SystemVerilog
// Phase accumulator module
module phase_accumulator #(
    parameter PHASE_WIDTH = 12
)(
    input clk,
    input rst,
    input [PHASE_WIDTH-1:0] phase_incr,
    output [PHASE_WIDTH-1:0] phase_out
);
    reg [PHASE_WIDTH-1:0] phase_accum;
    
    always @(posedge clk) begin
        if (rst)
            phase_accum <= 0;
        else
            phase_accum <= phase_accum + phase_incr;
    end
    
    assign phase_out = phase_accum;
endmodule

// Sine ROM module
module sine_rom #(
    parameter AMP_WIDTH = 8
)(
    input [3:0] addr,
    output [AMP_WIDTH-1:0] sine_out
);
    reg [AMP_WIDTH-1:0] sine_rom [0:15];
    
    initial begin
        sine_rom[0] = 8'd128; sine_rom[1] = 8'd176; sine_rom[2] = 8'd218; sine_rom[3] = 8'd245;
        sine_rom[4] = 8'd255; sine_rom[5] = 8'd245; sine_rom[6] = 8'd218; sine_rom[7] = 8'd176;
        sine_rom[8] = 8'd128; sine_rom[9] = 8'd79;  sine_rom[10] = 8'd37; sine_rom[11] = 8'd10;
        sine_rom[12] = 8'd0;  sine_rom[13] = 8'd10; sine_rom[14] = 8'd37; sine_rom[15] = 8'd79;
    end
    
    assign sine_out = sine_rom[addr];
endmodule

// Top-level NCO module
module nco_sine #(
    parameter PHASE_WIDTH = 12,
    parameter AMP_WIDTH = 8
)(
    input clk,
    input rst,
    input [PHASE_WIDTH-1:0] phase_incr,
    output [AMP_WIDTH-1:0] sine_wave
);
    wire [PHASE_WIDTH-1:0] phase_out;
    wire [3:0] rom_addr;
    
    // Extract ROM address from phase accumulator
    assign rom_addr = phase_out[PHASE_WIDTH-1:PHASE_WIDTH-4];
    
    // Instantiate phase accumulator
    phase_accumulator #(
        .PHASE_WIDTH(PHASE_WIDTH)
    ) phase_acc_inst (
        .clk(clk),
        .rst(rst),
        .phase_incr(phase_incr),
        .phase_out(phase_out)
    );
    
    // Instantiate sine ROM
    sine_rom #(
        .AMP_WIDTH(AMP_WIDTH)
    ) sine_rom_inst (
        .addr(rom_addr),
        .sine_out(sine_wave)
    );
endmodule