//SystemVerilog
module cross_domain_sync #(parameter BUS_WIDTH = 16) (
    // Source domain signals
    input  wire                  src_clk,
    input  wire                  src_rst,
    input  wire [BUS_WIDTH-1:0]  src_data,
    input  wire                  src_valid,
    output wire                  src_ready,
    
    // Destination domain signals
    input  wire                  dst_clk,
    input  wire                  dst_rst,
    output wire [BUS_WIDTH-1:0]  dst_data,
    output wire                  dst_valid,
    input  wire                  dst_ready
);
    // Internal signals for domain crossing
    wire src_toggle_flag;
    wire [2:0] dst_sync_flag;
    
    // Source domain module instantiation
    source_domain_controller #(
        .BUS_WIDTH(BUS_WIDTH)
    ) src_ctrl (
        .clk(src_clk),
        .rst(src_rst),
        .data_in(src_data),
        .valid_in(src_valid),
        .ready_out(src_ready),
        .toggle_flag_out(src_toggle_flag),
        .dst_sync_flag_in(dst_sync_flag[2])
    );
    
    // Destination domain module instantiation
    destination_domain_controller #(
        .BUS_WIDTH(BUS_WIDTH)
    ) dst_ctrl (
        .clk(dst_clk),
        .rst(dst_rst),
        .src_toggle_flag_in(src_toggle_flag),
        .sync_flag_out(dst_sync_flag),
        .data_out(dst_data),
        .valid_out(dst_valid),
        .ready_in(dst_ready)
    );
    
endmodule

// Source domain controller module
module source_domain_controller #(
    parameter BUS_WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire [BUS_WIDTH-1:0]  data_in,
    input  wire                  valid_in,
    output reg                   ready_out,
    output reg                   toggle_flag_out,
    input  wire                  dst_sync_flag_in
);
    // Internal signals
    wire is_data_transfer;
    wire is_ack_received;
    reg next_toggle_flag;
    reg next_ready_out;

    // Pre-compute next state values to reduce critical path
    assign is_data_transfer = valid_in && ready_out;
    assign is_ack_received = (dst_sync_flag_in == toggle_flag_out);
    
    // Combinational logic for next state calculation
    always @(*) begin
        next_toggle_flag = toggle_flag_out;
        next_ready_out = ready_out;
        
        if (is_data_transfer) begin
            next_toggle_flag = ~toggle_flag_out;
            next_ready_out = 1'b0;
        end else if (is_ack_received) begin
            next_ready_out = 1'b1;
        end
    end

    // State update with pre-computed values
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset condition
            toggle_flag_out <= 1'b0;
            ready_out <= 1'b1;
        end else begin
            // Update with pre-computed values
            toggle_flag_out <= next_toggle_flag;
            ready_out <= next_ready_out;
        end
    end
endmodule

// Destination domain controller module
module destination_domain_controller #(
    parameter BUS_WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  src_toggle_flag_in,
    output wire [2:0]            sync_flag_out,
    output reg  [BUS_WIDTH-1:0]  data_out,
    output reg                   valid_out,
    input  wire                  ready_in
);
    // Internal signals and registers
    reg [1:0] sync_stage;
    reg sync_toggle;
    reg next_valid_out;
    reg [BUS_WIDTH-1:0] next_data_out;
    wire is_data_edge_detected;
    wire is_data_consumed;
    
    // Synchronizer registers (moved earlier in the pipeline)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_stage <= 2'b00;
            sync_toggle <= 1'b0;
        end else begin
            sync_stage <= {sync_stage[0], src_toggle_flag_in};
            sync_toggle <= sync_stage[1];
        end
    end
    
    // Create synchronization flag output
    assign sync_flag_out = {sync_stage, src_toggle_flag_in};
    
    // Pre-compute conditions to reduce critical path
    assign is_data_edge_detected = (sync_toggle != sync_stage[1]) && !valid_out;
    assign is_data_consumed = valid_out && ready_in;
    
    // Pre-compute next state values
    always @(*) begin
        next_valid_out = valid_out;
        next_data_out = data_out;
        
        if (is_data_edge_detected) begin
            next_data_out = {BUS_WIDTH{sync_stage[1]}};  // Use synchronized data
            next_valid_out = 1'b1;
        end else if (is_data_consumed) begin
            next_valid_out = 1'b0;
        end
    end
    
    // State update with pre-computed values
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset condition
            valid_out <= 1'b0;
            data_out <= {BUS_WIDTH{1'b0}};
        end else begin
            // Update with pre-computed values
            valid_out <= next_valid_out;
            data_out <= next_data_out;
        end
    end
endmodule