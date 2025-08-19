//SystemVerilog
module preloadable_counter (
    input wire clk, sync_rst, load, en,
    input wire [5:0] preset_val,
    output reg [5:0] q
);
    // Registered control signals
    reg sync_rst_reg, load_reg, en_reg;
    reg [5:0] preset_val_reg;
    
    // Register input signals to reduce input-to-register delay
    always @(posedge clk) begin
        sync_rst_reg <= sync_rst;
        load_reg <= load;
        en_reg <= en;
        preset_val_reg <= preset_val;
    end
    
    // Main counter logic with registered inputs using case statement
    // Combined control signals for case statement
    reg [2:0] ctrl;
    
    always @(*) begin
        ctrl = {sync_rst_reg, load_reg, en_reg};
    end
    
    always @(posedge clk) begin
        case (ctrl)
            3'b100, 3'b101, 3'b110, 3'b111: // sync_rst_reg is high
                q <= 6'b000000;
            3'b010, 3'b011: // load_reg is high, sync_rst_reg is low
                q <= preset_val_reg;
            3'b001: // en_reg is high, sync_rst_reg and load_reg are low
                q <= q + 1'b1;
            3'b000: // All control signals are low
                q <= q; // Hold current value
        endcase
    end
endmodule