//SystemVerilog
//============================================================================
// Top-level module: Timer_PrescaleDown
//============================================================================
module Timer_PrescaleDown #(parameter DIV=16) (
    input clk, rst_n,
    // Handshake interface for loading initial value
    input        init_val_valid,
    output reg   init_val_ready,
    input [7:0]  init_val,
    // Handshake interface for timer output
    output reg   timeup_valid,
    input        timeup_ready,
    output       timeup
);
    // Internal signals for interconnection
    wire prescaler_tick;
    wire [7:0] counter_value;
    wire timeup_internal;
    reg  load_en;
    
    // Handshake logic for loading initial value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            init_val_ready <= 1'b1;
            load_en <= 1'b0;
        end else begin
            if (init_val_valid && init_val_ready) begin
                init_val_ready <= 1'b0;
                load_en <= 1'b1;
            end else begin
                load_en <= 1'b0;
                // Ready for next init value after 1 cycle delay
                if (!init_val_ready && !init_val_valid)
                    init_val_ready <= 1'b1;
            end
        end
    end
    
    // Handshake logic for timeup output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeup_valid <= 1'b0;
        end else begin
            if (timeup_internal && !timeup_valid) begin
                timeup_valid <= 1'b1;
            end else if (timeup_valid && timeup_ready) begin
                timeup_valid <= 1'b0;
            end
        end
    end
    
    // Prescaler submodule instantiation
    Prescaler_Unit #(
        .DIV(DIV)
    ) prescaler_inst (
        .clk(clk),
        .rst_n(rst_n),
        .prescaler_valid(1'b1),         // Always valid
        .prescaler_ready(),             // Not used at top level
        .prescaler_tick(prescaler_tick)
    );
    
    // Counter submodule instantiation
    Counter_Unit counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .load_en(load_en),
        .prescaler_tick(prescaler_tick),
        .init_val(init_val),
        .counter_value(counter_value),
        .timeup_internal(timeup_internal),
        .timeup(timeup)
    );
    
endmodule

//============================================================================
// Prescaler submodule - Divides the clock by DIV
//============================================================================
module Prescaler_Unit #(parameter DIV=16) (
    input clk,
    input rst_n,
    // Handshake interface
    input  prescaler_valid,
    output reg prescaler_ready,
    output prescaler_tick
);
    reg [$clog2(DIV)-1:0] ps_cnt;
    
    // Generate tick when prescaler reaches its final count
    assign prescaler_tick = prescaler_valid && prescaler_ready && (ps_cnt == 0);
    
    // Ready signal generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescaler_ready <= 1'b1;
        end
    end
    
    // Prescaler counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps_cnt <= 0;
        end else if (prescaler_valid && prescaler_ready) begin
            ps_cnt <= (ps_cnt == DIV-1) ? 0 : ps_cnt + 1;
        end
    end
    
endmodule

//============================================================================
// Counter submodule - Handles countdown and timeup signal generation
//============================================================================
module Counter_Unit (
    input clk,
    input rst_n,
    input load_en,
    input prescaler_tick,
    input [7:0] init_val,
    output reg [7:0] counter_value,
    output reg timeup_internal,
    output timeup
);
    
    // Assign timeup output 
    assign timeup = timeup_internal;
    
    // Counter value update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_value <= 0;
        end else if (load_en) begin
            counter_value <= init_val;
        end else if (prescaler_tick && counter_value > 0) begin
            counter_value <= counter_value - 1;
        end
    end
    
    // Timeup signal generation logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeup_internal <= 0;
        end else begin
            timeup_internal <= (counter_value == 0);
        end
    end
    
endmodule