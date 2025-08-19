//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: power_on_reset_sync
// Description: Top level module for power-on reset synchronization
///////////////////////////////////////////////////////////////////////////////
module power_on_reset_sync (
    input  wire clk,
    input  wire ext_rst_n,
    output wire por_rst_n
);
    // Internal signals
    wire ext_rst_sync_out;
    wire por_done_out;
    
    // External reset synchronizer module instance
    ext_reset_synchronizer u_ext_reset_sync (
        .clk           (clk),
        .ext_rst_n     (ext_rst_n),
        .ext_rst_sync  (ext_rst_sync_out)
    );
    
    // Power-on reset counter module instance
    por_counter_module u_por_counter (
        .clk           (clk),
        .ext_rst_n     (ext_rst_n),
        .por_done      (por_done_out)
    );
    
    // Register the combined reset output to improve timing
    reg por_rst_n_reg;
    
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            por_rst_n_reg <= 1'b0;
        end else begin
            por_rst_n_reg <= ext_rst_sync_out & por_done_out;
        end
    end
    
    assign por_rst_n = por_rst_n_reg;
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: ext_reset_synchronizer
// Description: Synchronizes external reset to the clock domain
///////////////////////////////////////////////////////////////////////////////
module ext_reset_synchronizer (
    input  wire clk,
    input  wire ext_rst_n,
    output wire ext_rst_sync
);
    // Pre-register the input value to reduce input path delay
    reg ext_rst_n_reg;
    reg [1:0] sync_reg;
    
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            ext_rst_n_reg <= 1'b0;
        end else begin
            ext_rst_n_reg <= 1'b1;
        end
    end
    
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            sync_reg <= 2'b00;
        end else begin
            sync_reg <= {sync_reg[0], ext_rst_n_reg};
        end
    end
    
    assign ext_rst_sync = sync_reg[1];
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: por_counter_module
// Description: Handles power-on reset counter sequence
///////////////////////////////////////////////////////////////////////////////
module por_counter_module #(
    parameter COUNTER_WIDTH = 3,
    parameter MAX_COUNT = {COUNTER_WIDTH{1'b1}}  // Default max value (all 1's)
)(
    input  wire clk,
    input  wire ext_rst_n,
    output wire por_done
);
    reg [COUNTER_WIDTH-1:0] counter;
    reg                     por_done_reg;
    // Pre-compute the next counter value to reduce critical path
    reg [COUNTER_WIDTH-1:0] next_counter;
    reg                     next_por_done;
    
    always @(*) begin
        if (!por_done_reg) begin
            if (counter < MAX_COUNT) begin
                next_counter = counter + 1'b1;
                next_por_done = 1'b0;
            end else begin
                next_counter = counter;
                next_por_done = 1'b1;
            end
        end else begin
            next_counter = counter;
            next_por_done = por_done_reg;
        end
    end
    
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            por_done_reg <= 1'b0;
        end else begin
            counter <= next_counter;
            por_done_reg <= next_por_done;
        end
    end
    
    assign por_done = por_done_reg;
    
endmodule