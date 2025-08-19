//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module
module rz_codec (
    input wire clk, rst_n,
    input wire data_in,       // For encoding
    input wire rz_in,         // For decoding
    output wire rz_out,       // Encoded output
    output wire data_out,     // Decoded output
    output wire valid_out     // Valid decoded bit
);
    // Internal signals
    wire [1:0] bit_phase;

    // Phase generator module instantiation
    phase_generator phase_gen (
        .clk(clk),
        .rst_n(rst_n),
        .bit_phase(bit_phase)
    );

    // RZ encoder module instantiation
    rz_encoder encoder (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .bit_phase(bit_phase),
        .rz_out(rz_out)
    );

    // RZ decoder module instantiation
    rz_decoder decoder (
        .clk(clk),
        .rst_n(rst_n),
        .rz_in(rz_in),
        .bit_phase(bit_phase),
        .data_out(data_out),
        .valid_out(valid_out)
    );
endmodule

// Phase generator module
module phase_generator (
    input wire clk,
    input wire rst_n,
    output reg [1:0] bit_phase
);
    // Combinational logic for next phase value
    wire [1:0] next_phase;
    
    assign next_phase = bit_phase + 1'b1;
    
    // Sequential logic for phase update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            bit_phase <= 2'b00;
        else 
            bit_phase <= next_phase;
    end
endmodule

// RZ encoder module
module rz_encoder (
    input wire clk,
    input wire rst_n,
    input wire data_in,
    input wire [1:0] bit_phase,
    output reg rz_out
);
    // Combinational logic for RZ encoding
    wire rz_next;
    
    assign rz_next = (bit_phase == 2'b00) ? data_in : 
                     (bit_phase == 2'b01) ? rz_out : 1'b0;
    
    // Sequential logic for output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            rz_out <= 1'b0;
        else
            rz_out <= rz_next;
    end
endmodule

// RZ decoder module
module rz_decoder (
    input wire clk,
    input wire rst_n,
    input wire rz_in,
    input wire [1:0] bit_phase,
    output reg data_out,
    output wire valid_out
);
    // Internal registers
    reg sample_data;
    
    // Combinational logic
    wire sample_next;
    wire data_next;
    wire phase_is_sample;
    wire phase_is_update;
    
    assign phase_is_sample = (bit_phase == 2'b00);
    assign phase_is_update = (bit_phase == 2'b10);
    assign valid_out = phase_is_update;
    
    assign sample_next = phase_is_sample ? rz_in : sample_data;
    assign data_next = phase_is_update ? (sample_data & ~rz_in) : data_out;
    
    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sample_data <= 1'b0;
            data_out <= 1'b0;
        end
        else begin
            sample_data <= sample_next;
            data_out <= data_next;
        end
    end
endmodule