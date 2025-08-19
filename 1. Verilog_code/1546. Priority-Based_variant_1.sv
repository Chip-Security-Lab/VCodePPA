//SystemVerilog
///////////////////////////////////////////////////////////
// File: priority_shadow_reg_top.v
// IEEE 1364-2005 Verilog standard
///////////////////////////////////////////////////////////

module priority_shadow_reg_top #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_high_pri,
    input wire high_pri_valid,
    input wire [WIDTH-1:0] data_low_pri,
    input wire low_pri_valid,
    output wire [WIDTH-1:0] shadow_out
);
    // Internal signals
    wire [WIDTH-1:0] data_selected;
    wire data_valid;
    
    // Submodule instantiations
    priority_selector #(
        .WIDTH(WIDTH)
    ) u_priority_selector (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_high  (data_high_pri),
        .high_valid (high_pri_valid),
        .data_low   (data_low_pri),
        .low_valid  (low_pri_valid),
        .data_out   (data_selected),
        .valid_out  (data_valid)
    );
    
    shadow_register #(
        .WIDTH(WIDTH)
    ) u_shadow_register (
        .clk       (clk),
        .rst_n     (rst_n),
        .data_in   (data_selected),
        .data_valid(data_valid),
        .shadow_out(shadow_out)
    );
    
endmodule

///////////////////////////////////////////////////////////
// File: priority_selector.v
// Handles priority-based input selection logic
///////////////////////////////////////////////////////////

module priority_selector #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_high,
    input wire high_valid,
    input wire [WIDTH-1:0] data_low,
    input wire low_valid,
    output reg [WIDTH-1:0] data_out,
    output reg valid_out
);
    // Pre-calculated control signals to reduce critical path
    reg any_valid;
    reg [WIDTH-1:0] mux_result;
    reg next_valid;
    
    // Split the logic into parallel paths to balance delay
    always @(*) begin
        // Calculate validity and mux results in parallel
        any_valid = high_valid | low_valid;
        next_valid = any_valid;
        
        // Use separate paths for different data sources to balance logic
        case ({high_valid, low_valid})
            2'b10, 2'b11: mux_result = data_high; // High priority takes precedence when both valid
            2'b01:        mux_result = data_low;
            default:      mux_result = {WIDTH{1'b0}};
        endcase
    end
    
    // Register update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end
        else begin
            data_out <= mux_result;
            valid_out <= next_valid;
        end
    end
endmodule

///////////////////////////////////////////////////////////
// File: shadow_register.v
// Handles shadow register update logic
///////////////////////////////////////////////////////////

module shadow_register #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire data_valid,
    output reg [WIDTH-1:0] shadow_out
);
    // Optimized shadow register with direct update path
    // Removed extra pipeline stage to reduce latency
    
    // Use enable-based update instead of conditional assignment
    // This simplifies the critical path
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_out <= {WIDTH{1'b0}};
        end
        else if (data_valid) begin
            shadow_out <= data_in;
        end
    end
endmodule