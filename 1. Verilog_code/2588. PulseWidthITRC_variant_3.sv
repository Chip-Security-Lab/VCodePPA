//SystemVerilog
module PulseWidthDetector (
    input wire clk,
    input wire rstn,
    input wire irq_in,
    output reg long_pulse
);
    reg [3:0] pulse_counter;
    reg prev_irq;
    wire rising_edge = irq_in && !prev_irq;
    wire falling_edge = !irq_in && prev_irq;
    
    // LUT-based counter increment
    reg [3:0] lut_counter [0:15];
    initial begin
        lut_counter[0] = 4'd1;
        lut_counter[1] = 4'd2;
        lut_counter[2] = 4'd3;
        lut_counter[3] = 4'd4;
        lut_counter[4] = 4'd5;
        lut_counter[5] = 4'd6;
        lut_counter[6] = 4'd7;
        lut_counter[7] = 4'd8;
        lut_counter[8] = 4'd9;
        lut_counter[9] = 4'd10;
        lut_counter[10] = 4'd11;
        lut_counter[11] = 4'd12;
        lut_counter[12] = 4'd13;
        lut_counter[13] = 4'd14;
        lut_counter[14] = 4'd15;
        lut_counter[15] = 4'd0;
    end
    
    wire [3:0] next_counter = lut_counter[pulse_counter];
    wire counter_overflow = &pulse_counter[2:0];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pulse_counter <= 0;
            prev_irq <= 0;
            long_pulse <= 0;
        end else begin
            pulse_counter <= rising_edge ? 4'd1 : 
                           (irq_in ? next_counter : 4'd0);
            
            long_pulse <= (long_pulse && !falling_edge) || 
                         (irq_in && counter_overflow);
                
            prev_irq <= irq_in;
        end
    end
endmodule

module PriorityEncoder #(parameter CHANNELS=4) (
    input wire [CHANNELS-1:0] long_pulse,
    output reg irq_out,
    output reg [1:0] irq_src
);
    // LUT-based priority encoding
    reg [2:0] priority_lut [0:15];
    initial begin
        priority_lut[0] = 3'b000;
        priority_lut[1] = 3'b101;
        priority_lut[2] = 3'b110;
        priority_lut[3] = 3'b111;
        priority_lut[4] = 3'b100;
        priority_lut[5] = 3'b101;
        priority_lut[6] = 3'b110;
        priority_lut[7] = 3'b111;
        priority_lut[8] = 3'b100;
        priority_lut[9] = 3'b101;
        priority_lut[10] = 3'b110;
        priority_lut[11] = 3'b111;
        priority_lut[12] = 3'b100;
        priority_lut[13] = 3'b101;
        priority_lut[14] = 3'b110;
        priority_lut[15] = 3'b111;
    end
    
    wire [2:0] priority_result = priority_lut[long_pulse];
    
    always @(*) begin
        irq_out = |long_pulse;
        irq_src = priority_result[1:0];
    end
endmodule

module PulseWidthITRC #(parameter CHANNELS=4) (
    input wire clk,
    input wire rstn,
    input wire [CHANNELS-1:0] irq_in,
    output wire irq_out,
    output wire [1:0] irq_src
);
    wire [CHANNELS-1:0] long_pulse;

    genvar i;
    generate
        for (i = 0; i < CHANNELS; i = i + 1) begin : gen_detectors
            PulseWidthDetector detector (
                .clk(clk),
                .rstn(rstn),
                .irq_in(irq_in[i]),
                .long_pulse(long_pulse[i])
            );
        end
    endgenerate

    PriorityEncoder #(CHANNELS) encoder (
        .long_pulse(long_pulse),
        .irq_out(irq_out),
        .irq_src(irq_src)
    );
endmodule