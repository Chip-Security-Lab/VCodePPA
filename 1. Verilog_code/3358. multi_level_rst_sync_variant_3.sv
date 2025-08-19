//SystemVerilog
module multi_level_rst_sync (
    input  wire clock,
    input  wire hard_rst_n,
    input  wire soft_rst_n,
    output wire system_rst_n,
    output wire periph_rst_n
);
    reg [1:0] hard_rst_sync;
    reg [1:0] soft_rst_sync;
    
    // System reset signal - registered earlier in the path
    reg system_rst_n_reg;
    
    // Peripheral reset signal - registered earlier in the path
    reg periph_rst_n_reg;
    
    // Hard reset synchronization
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n)
            hard_rst_sync <= 2'b00;
        else
            hard_rst_sync <= {hard_rst_sync[0], 1'b1};
    end
    
    // Register system reset directly from hard_rst_sync
    // Eliminated buffer registers to reduce latency
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n)
            system_rst_n_reg <= 1'b0;
        else
            system_rst_n_reg <= hard_rst_sync[1];
    end
    
    // Soft reset synchronization with direct dependency on hard_rst_sync
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n)
            soft_rst_sync <= 2'b00;
        else if (!soft_rst_n)
            soft_rst_sync <= 2'b00;
        else
            soft_rst_sync <= {soft_rst_sync[0], 1'b1};
    end
    
    // Register peripheral reset directly
    always @(posedge clock or negedge hard_rst_n) begin
        if (!hard_rst_n)
            periph_rst_n_reg <= 1'b0;
        else if (!soft_rst_n)
            periph_rst_n_reg <= 1'b0;
        else
            periph_rst_n_reg <= soft_rst_sync[1];
    end
    
    // Assign registered outputs
    assign system_rst_n = system_rst_n_reg;
    assign periph_rst_n = periph_rst_n_reg;
endmodule