//SystemVerilog
// Top-level module with pipelined architecture
module usb_isoc_manager #(
    parameter NUM_ENDPOINTS = 4,
    parameter DATA_WIDTH = 16
)(
    input wire clock, reset_b,
    input wire sof_received,
    input wire [10:0] frame_number,
    input wire [3:0] endpoint_select,
    input wire transfer_ready,
    input wire [DATA_WIDTH-1:0] tx_data,
    output wire transfer_active,
    output wire [DATA_WIDTH-1:0] rx_data,
    output wire [NUM_ENDPOINTS-1:0] endpoint_status,
    output wire [1:0] bandwidth_state
);
    // Pipeline control signals
    reg sof_received_stage1, sof_received_stage2;
    reg [10:0] frame_number_stage1, frame_number_stage2;
    reg [3:0] endpoint_select_stage1, endpoint_select_stage2;
    reg transfer_ready_stage1, transfer_ready_stage2;
    reg [DATA_WIDTH-1:0] tx_data_stage1, tx_data_stage2;
    
    // Pipeline valid signals
    reg pipeline_valid_stage1, pipeline_valid_stage2, pipeline_valid_stage3;
    
    // Internal connections with pipeline registers
    wire [10:0] last_frame_array [0:NUM_ENDPOINTS-1];
    reg [10:0] last_frame_array_stage1 [0:NUM_ENDPOINTS-1];
    reg [10:0] last_frame_array_stage2 [0:NUM_ENDPOINTS-1];
    
    wire [2:0] interval_array [0:NUM_ENDPOINTS-1];
    reg [2:0] interval_array_stage1 [0:NUM_ENDPOINTS-1];
    reg [2:0] interval_array_stage2 [0:NUM_ENDPOINTS-1];
    
    // Intermediate outputs with pipeline registers
    wire [NUM_ENDPOINTS-1:0] endpoint_status_internal;
    reg [NUM_ENDPOINTS-1:0] endpoint_status_stage1, endpoint_status_stage2;
    
    wire transfer_active_internal;
    reg transfer_active_stage1, transfer_active_stage2;
    
    wire [DATA_WIDTH-1:0] rx_data_internal;
    reg [DATA_WIDTH-1:0] rx_data_stage1, rx_data_stage2;
    
    wire [1:0] bandwidth_state_internal;
    reg [1:0] bandwidth_state_stage1, bandwidth_state_stage2;
    
    // Pipeline stage 1: Input registration and endpoint configuration
    integer i;
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            sof_received_stage1 <= 1'b0;
            frame_number_stage1 <= 11'd0;
            endpoint_select_stage1 <= 4'd0;
            transfer_ready_stage1 <= 1'b0;
            tx_data_stage1 <= {DATA_WIDTH{1'b0}};
            pipeline_valid_stage1 <= 1'b0;
            
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                interval_array_stage1[i] <= 3'd0;
                last_frame_array_stage1[i] <= 11'd0;
            end
        end else begin
            sof_received_stage1 <= sof_received;
            frame_number_stage1 <= frame_number;
            endpoint_select_stage1 <= endpoint_select;
            transfer_ready_stage1 <= transfer_ready;
            tx_data_stage1 <= tx_data;
            pipeline_valid_stage1 <= 1'b1;
            
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                interval_array_stage1[i] <= interval_array[i];
                last_frame_array_stage1[i] <= last_frame_array[i];
            end
        end
    end
    
    // Pipeline stage 2: Frame tracking and endpoint status calculation
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            sof_received_stage2 <= 1'b0;
            frame_number_stage2 <= 11'd0;
            endpoint_select_stage2 <= 4'd0;
            transfer_ready_stage2 <= 1'b0;
            tx_data_stage2 <= {DATA_WIDTH{1'b0}};
            pipeline_valid_stage2 <= 1'b0;
            endpoint_status_stage1 <= {NUM_ENDPOINTS{1'b0}};
            
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                interval_array_stage2[i] <= 3'd0;
                last_frame_array_stage2[i] <= 11'd0;
            end
        end else begin
            sof_received_stage2 <= sof_received_stage1;
            frame_number_stage2 <= frame_number_stage1;
            endpoint_select_stage2 <= endpoint_select_stage1;
            transfer_ready_stage2 <= transfer_ready_stage1;
            tx_data_stage2 <= tx_data_stage1;
            pipeline_valid_stage2 <= pipeline_valid_stage1;
            endpoint_status_stage1 <= endpoint_status_internal;
            
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                interval_array_stage2[i] <= interval_array_stage1[i];
                last_frame_array_stage2[i] <= last_frame_array_stage1[i];
            end
        end
    end
    
    // Pipeline stage 3: Bandwidth management and output registration
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            pipeline_valid_stage3 <= 1'b0;
            endpoint_status_stage2 <= {NUM_ENDPOINTS{1'b0}};
            transfer_active_stage2 <= 1'b0;
            rx_data_stage2 <= {DATA_WIDTH{1'b0}};
            bandwidth_state_stage2 <= 2'b00;
        end else begin
            pipeline_valid_stage3 <= pipeline_valid_stage2;
            endpoint_status_stage2 <= endpoint_status_stage1;
            transfer_active_stage2 <= transfer_active_internal;
            rx_data_stage2 <= rx_data_internal;
            bandwidth_state_stage2 <= bandwidth_state_internal;
        end
    end
    
    // Connect outputs to final pipeline stage
    assign endpoint_status = endpoint_status_stage2;
    assign transfer_active = transfer_active_stage2;
    assign rx_data = rx_data_stage2;
    assign bandwidth_state = bandwidth_state_stage2;
    
    // Instantiate endpoint configuration manager with pipelined connections
    pipelined_endpoint_config_manager #(
        .NUM_ENDPOINTS(NUM_ENDPOINTS)
    ) endpoint_config_inst (
        .clock(clock),
        .reset_b(reset_b),
        .pipeline_valid(pipeline_valid_stage1),
        .interval_array(interval_array)
    );
    
    // Instantiate frame tracking module with pipelined connections
    pipelined_frame_tracker #(
        .NUM_ENDPOINTS(NUM_ENDPOINTS)
    ) frame_tracker_inst (
        .clock(clock),
        .reset_b(reset_b),
        .pipeline_valid(pipeline_valid_stage2),
        .sof_received(sof_received_stage1),
        .frame_number(frame_number_stage1),
        .interval_array(interval_array_stage1),
        .last_frame_array(last_frame_array),
        .endpoint_status(endpoint_status_internal)
    );
    
    // Instantiate bandwidth manager with pipelined connections
    pipelined_bandwidth_manager #(
        .NUM_ENDPOINTS(NUM_ENDPOINTS),
        .DATA_WIDTH(DATA_WIDTH)
    ) bandwidth_manager_inst (
        .clock(clock),
        .reset_b(reset_b),
        .pipeline_valid(pipeline_valid_stage2),
        .endpoint_select(endpoint_select_stage2),
        .transfer_ready(transfer_ready_stage2),
        .tx_data(tx_data_stage2),
        .transfer_active(transfer_active_internal),
        .rx_data(rx_data_internal),
        .bandwidth_state(bandwidth_state_internal)
    );
    
endmodule

// Pipelined endpoint configuration manager
module pipelined_endpoint_config_manager #(
    parameter NUM_ENDPOINTS = 4
)(
    input wire clock,
    input wire reset_b,
    input wire pipeline_valid,
    output reg [2:0] interval_array [0:NUM_ENDPOINTS-1]
);
    integer i;
    reg [2:0] interval_array_next [0:NUM_ENDPOINTS-1];
    
    always @(*) begin
        for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
            interval_array_next[i] = interval_array[i];
        end
    end
    
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                interval_array[i] <= 3'd1;  // Default interval of 1 frame
            end
        end else if (pipeline_valid) begin
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                interval_array[i] <= interval_array_next[i];
            end
        end
    end
endmodule

// Pipelined frame tracking module
module pipelined_frame_tracker #(
    parameter NUM_ENDPOINTS = 4
)(
    input wire clock,
    input wire reset_b,
    input wire pipeline_valid,
    input wire sof_received,
    input wire [10:0] frame_number,
    input wire [2:0] interval_array [0:NUM_ENDPOINTS-1],
    output reg [10:0] last_frame_array [0:NUM_ENDPOINTS-1],
    output reg [NUM_ENDPOINTS-1:0] endpoint_status
);
    integer i;
    reg [NUM_ENDPOINTS-1:0] endpoint_status_next;
    reg [10:0] last_frame_array_next [0:NUM_ENDPOINTS-1];
    
    // Stage 1: Compute next status values
    always @(*) begin
        endpoint_status_next = endpoint_status;
        
        for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
            last_frame_array_next[i] = last_frame_array[i];
        end
        
        if (sof_received) begin
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                if ((frame_number - last_frame_array[i]) >= {8'd0, interval_array[i]}) begin
                    endpoint_status_next[i] = 1'b1;
                    last_frame_array_next[i] = frame_number;
                end
            end
        end
    end
    
    // Stage 2: Register the computed values
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            endpoint_status <= {NUM_ENDPOINTS{1'b0}};
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                last_frame_array[i] <= 11'h7FF;  // Invalid frame number
            end
        end else if (pipeline_valid) begin
            endpoint_status <= endpoint_status_next;
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                last_frame_array[i] <= last_frame_array_next[i];
            end
        end
    end
endmodule

// Pipelined bandwidth manager
module pipelined_bandwidth_manager #(
    parameter NUM_ENDPOINTS = 4,
    parameter DATA_WIDTH = 16
)(
    input wire clock,
    input wire reset_b,
    input wire pipeline_valid,
    input wire [3:0] endpoint_select,
    input wire transfer_ready,
    input wire [DATA_WIDTH-1:0] tx_data,
    output reg transfer_active,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg [1:0] bandwidth_state
);
    // Bandwidth reservation states
    localparam IDLE = 2'b00;
    localparam RESERVED = 2'b01;
    localparam ACTIVE = 2'b10;
    localparam COMPLETE = 2'b11;
    
    // Internal pipeline registers
    reg transfer_active_next;
    reg [DATA_WIDTH-1:0] rx_data_next;
    reg [1:0] bandwidth_state_next;
    
    // Stage 1: Compute next state values
    always @(*) begin
        transfer_active_next = transfer_active;
        rx_data_next = rx_data;
        bandwidth_state_next = bandwidth_state;
        
        case (bandwidth_state)
            IDLE: begin
                if (transfer_ready) begin
                    bandwidth_state_next = RESERVED;
                    transfer_active_next = 1'b0;
                end
            end
            
            RESERVED: begin
                bandwidth_state_next = ACTIVE;
                transfer_active_next = 1'b1;
                rx_data_next = tx_data; // Capture input data
            end
            
            ACTIVE: begin
                if (!transfer_ready) begin
                    bandwidth_state_next = COMPLETE;
                    transfer_active_next = 1'b0;
                end else begin
                    rx_data_next = tx_data; // Update data while active
                end
            end
            
            COMPLETE: begin
                bandwidth_state_next = IDLE;
            end
            
            default: begin
                bandwidth_state_next = IDLE;
            end
        endcase
    end
    
    // Stage 2: Register the computed values
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            transfer_active <= 1'b0;
            bandwidth_state <= IDLE;
            rx_data <= {DATA_WIDTH{1'b0}};
        end else if (pipeline_valid) begin
            transfer_active <= transfer_active_next;
            bandwidth_state <= bandwidth_state_next;
            rx_data <= rx_data_next;
        end
    end
endmodule