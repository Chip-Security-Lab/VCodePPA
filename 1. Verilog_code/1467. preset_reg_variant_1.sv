//SystemVerilog
module preset_reg(
    input clk, sync_preset, load,
    input [11:0] data_in,
    output reg [11:0] data_out
);
    // Control signals for next cycle operation
    reg sync_preset_next, load_next;
    
    // Output data preparation logic
    reg [11:0] next_data;
    
    // Determine next state based on current inputs
    always @(*) begin
        sync_preset_next = sync_preset;
        load_next = load;
        
        if (sync_preset)
            next_data = 12'hFFF;  // Preset to all 1s
        else if (load)
            next_data = data_in;
        else
            next_data = data_out; // Hold current value
    end
    
    // Register the outputs directly
    always @(posedge clk) begin
        data_out <= next_data;
    end
endmodule