//SystemVerilog
module multi_phase_div #(parameter N=4) (
    input wire clk, rst,
    output wire [3:0] phase_out
);
    wire [1:0] cnt;
    
    // Instantiate sequential logic module
    counter_seq counter_inst (
        .clk(clk),
        .rst(rst),
        .cnt_out(cnt)
    );

    // Instantiate combinational logic module
    phase_decoder_comb decoder_inst (
        .cnt_in(cnt),
        .phase_out(phase_out)
    );
endmodule

// Sequential logic module for counter
module counter_seq (
    input wire clk, rst,
    output reg [1:0] cnt_out
);
    always @(posedge clk) begin
        if(rst) 
            cnt_out <= 2'b00;
        else 
            cnt_out <= cnt_out + 2'b01;
    end
endmodule

// Combinational logic module for phase decoding
module phase_decoder_comb (
    input wire [1:0] cnt_in,
    output wire [3:0] phase_out
);
    // Internal one-hot encoded signal
    wire [3:0] decoded_phase;
    
    // Optimized one-hot encoding using barrel shifter
    assign decoded_phase = 4'b0001 << cnt_in;
    
    // Connect to output in the correct order
    assign phase_out = {
        decoded_phase[3],
        decoded_phase[2],
        decoded_phase[1],
        decoded_phase[0]
    };
endmodule