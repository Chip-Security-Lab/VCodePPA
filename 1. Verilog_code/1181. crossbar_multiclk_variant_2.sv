//SystemVerilog
module crossbar_multiclk #(
    parameter DW = 8
)(
    input  wire          clk_a,
    input  wire          clk_b,
    input  wire          rst_a,
    input  wire          rst_b,
    input  wire [1:0][DW-1:0] din_a,
    input  wire          din_valid_a,
    output wire          din_ready_a,
    output wire [1:0][DW-1:0] dout_b,
    output wire          dout_valid_b,
    input  wire          dout_ready_b
);
    // Internal wires for connecting submodules
    wire [1:0][DW-1:0] din_a_registered;
    wire               din_valid_a_registered;
    wire               din_ready_a_internal;
    
    wire [1:0][DW-1:0] sync_data;
    wire               sync_valid;
    
    // Assign ready signal to input
    assign din_ready_a = din_ready_a_internal;
    
    // Input registration in clk_a domain
    input_register #(
        .DW(DW)
    ) u_input_register (
        .clk       (clk_a),
        .rst       (rst_a),
        .din       (din_a),
        .din_valid (din_valid_a),
        .din_ready (din_ready_a_internal),
        .dout      (din_a_registered),
        .dout_valid(din_valid_a_registered)
    );
    
    // First stage of clock domain crossing (clk_a domain)
    cdc_first_stage #(
        .DW(DW)
    ) u_cdc_first_stage (
        .clk       (clk_a),
        .rst       (rst_a),
        .din       (din_a_registered),
        .din_valid (din_valid_a_registered),
        .dout      (sync_data),
        .dout_valid(sync_valid)
    );
    
    // Second stage of clock domain crossing (clk_b domain)
    cdc_second_stage #(
        .DW(DW)
    ) u_cdc_second_stage (
        .clk       (clk_b),
        .rst       (rst_b),
        .din       (sync_data),
        .din_valid (sync_valid),
        .dout      (dout_b),
        .dout_valid(dout_valid_b),
        .dout_ready(dout_ready_b)
    );
endmodule

// Input registration module - handles input signal registration with pipelined control
module input_register #(
    parameter DW = 8
)(
    input  wire          clk,
    input  wire          rst,
    input  wire [1:0][DW-1:0] din,
    input  wire          din_valid,
    output wire          din_ready,
    output reg  [1:0][DW-1:0] dout,
    output reg           dout_valid
);
    // Pipeline stage status
    reg stage_busy;
    
    // Ready when not busy
    assign din_ready = ~stage_busy;
    
    always @(posedge clk) begin
        if (rst) begin
            dout <= '0;
            dout_valid <= 1'b0;
            stage_busy <= 1'b0;
        end
        else begin
            // Register new data when valid input and stage ready
            if (din_valid && ~stage_busy) begin
                dout <= din;
                dout_valid <= 1'b1;
                stage_busy <= 1'b1;
            end
            else if (stage_busy) begin
                // Data has been processed, can accept new data
                stage_busy <= 1'b0;
                dout_valid <= 1'b0;
            end
            else begin
                dout_valid <= 1'b0;
            end
        end
    end
endmodule

// CDC first stage module - first stage of clock domain crossing with pipeline control
module cdc_first_stage #(
    parameter DW = 8
)(
    input  wire          clk,
    input  wire          rst,
    input  wire [1:0][DW-1:0] din,
    input  wire          din_valid,
    output reg  [1:0][DW-1:0] dout,
    output reg           dout_valid
);
    // Pipeline registers for intermediate stages
    reg [1:0][DW-1:0] data_stage1;
    reg               valid_stage1;
    
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= '0;
            valid_stage1 <= 1'b0;
            dout <= '0;
            dout_valid <= 1'b0;
        end
        else begin
            // First pipeline stage
            if (din_valid) begin
                data_stage1 <= din;
                valid_stage1 <= 1'b1;
            end
            else begin
                valid_stage1 <= 1'b0;
            end
            
            // Second pipeline stage (output)
            dout <= data_stage1;
            dout_valid <= valid_stage1;
        end
    end
endmodule

// CDC second stage module - completes the clock domain crossing with multiple pipeline stages
module cdc_second_stage #(
    parameter DW = 8
)(
    input  wire          clk,
    input  wire          rst,
    input  wire [1:0][DW-1:0] din,
    input  wire          din_valid,
    output reg  [1:0][DW-1:0] dout,
    output reg           dout_valid,
    input  wire          dout_ready
);
    // Pipeline registers for intermediate stages
    reg [1:0][DW-1:0] data_stage1;
    reg               valid_stage1;
    reg [1:0][DW-1:0] data_stage2;
    reg               valid_stage2;
    
    // Control signals for pipeline
    reg               output_stall;
    
    always @(posedge clk) begin
        if (rst) begin
            data_stage1 <= '0;
            valid_stage1 <= 1'b0;
            data_stage2 <= '0;
            valid_stage2 <= 1'b0;
            dout <= '0;
            dout_valid <= 1'b0;
            output_stall <= 1'b0;
        end
        else begin
            // Check if output is stalled
            output_stall <= dout_valid && !dout_ready;
            
            // Only process new data if output isn't stalled
            if (!output_stall) begin
                // First pipeline stage - synchronization stage
                data_stage1 <= din;
                valid_stage1 <= din_valid;
                
                // Second pipeline stage - processing stage
                data_stage2 <= data_stage1;
                valid_stage2 <= valid_stage1;
                
                // Output stage
                dout <= data_stage2;
                dout_valid <= valid_stage2;
            end
        end
    end
endmodule