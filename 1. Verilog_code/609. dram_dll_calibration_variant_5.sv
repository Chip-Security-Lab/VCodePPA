//SystemVerilog
module dram_dll_calibration #(
    parameter CAL_CYCLES = 128
)(
    input clk,
    input calibrate,
    output reg dll_locked
);
    // Sequential logic signals
    reg [15:0] cal_counter;
    reg [15:0] carry_chain_reg;
    reg [15:0] cal_counter_reg;
    
    // Combinational logic signals
    wire [15:0] carry_chain;
    wire [15:0] next_counter;
    wire counter_eq_cal_cycles;
    
    // ===== COMBINATIONAL LOGIC =====
    
    // First stage - Calculate carry chain
    assign carry_chain[0] = calibrate;
    
    genvar i;
    generate
        for(i = 1; i < 16; i = i + 1) begin : carry_chain_gen
            assign carry_chain[i] = (cal_counter_reg[i-1] & carry_chain_reg[i-1]) | 
                                  (cal_counter_reg[i-1] & ~cal_counter_reg[i-1] & carry_chain_reg[i-1]);
        end
    endgenerate
    
    // Second stage - Calculate next counter value
    assign next_counter[0] = cal_counter_reg[0] ^ carry_chain_reg[0];
    
    generate
        for(i = 1; i < 16; i = i + 1) begin : next_counter_gen
            assign next_counter[i] = cal_counter_reg[i] ^ carry_chain_reg[i];
        end
    endgenerate
    
    // Calculate locked status (combinational)
    assign counter_eq_cal_cycles = (cal_counter == CAL_CYCLES);
    
    // ===== SEQUENTIAL LOGIC =====
    
    // Pipeline registers for carry chain and counter
    always @(posedge clk) begin
        carry_chain_reg <= carry_chain;
        cal_counter_reg <= cal_counter;
    end
    
    // Update counter and locked status
    always @(posedge clk) begin
        if(calibrate) begin
            cal_counter <= next_counter;
            dll_locked <= counter_eq_cal_cycles;
        end else begin
            cal_counter <= 0;
            dll_locked <= 0;
        end
    end
endmodule