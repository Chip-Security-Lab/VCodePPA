//SystemVerilog
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
    output reg transfer_active,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg [NUM_ENDPOINTS-1:0] endpoint_status,
    output reg [1:0] bandwidth_state
);
    // Bandwidth reservation states
    localparam IDLE = 2'b00;
    localparam RESERVED = 2'b01;
    localparam ACTIVE = 2'b10;
    localparam COMPLETE = 2'b11;
    
    // Per-endpoint configuration and state
    reg [2:0] interval [0:NUM_ENDPOINTS-1];
    reg [10:0] last_frame [0:NUM_ENDPOINTS-1];
    
    // Pipeline stage registers
    reg sof_received_stage1, sof_received_stage2;
    reg [10:0] frame_number_stage1, frame_number_stage2;
    reg [3:0] endpoint_select_stage1, endpoint_select_stage2;
    reg transfer_ready_stage1, transfer_ready_stage2;
    reg [DATA_WIDTH-1:0] tx_data_stage1, tx_data_stage2;
    
    // Pipeline control signals
    reg pipe_valid_stage1, pipe_valid_stage2, pipe_valid_stage3;
    reg [NUM_ENDPOINTS-1:0] endpoints_to_process_stage1;
    reg [NUM_ENDPOINTS-1:0] endpoints_to_process_stage2;
    
    // Intermediate calculation signals
    reg [10:0] frame_diff [0:NUM_ENDPOINTS-1];
    reg [NUM_ENDPOINTS-1:0] interval_check_stage1;
    reg [NUM_ENDPOINTS-1:0] interval_check_stage2;
    
    // Frame difference calculation logic - optimized
    wire [10:0] frame_diff_wire [0:NUM_ENDPOINTS-1];
    wire [NUM_ENDPOINTS-1:0] interval_check_wire;
    
    genvar g;
    generate
        for (g = 0; g < NUM_ENDPOINTS; g = g + 1) begin : gen_diff_calc
            assign frame_diff_wire[g] = frame_number - last_frame[g];
            assign interval_check_wire[g] = frame_diff_wire[g][10:3] != 0 || 
                                           frame_diff_wire[g][2:0] >= interval[g];
        end
    endgenerate
    
    integer i;
    
    // Stage 1: Input registration and frame difference calculation
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            sof_received_stage1 <= 1'b0;
            frame_number_stage1 <= 11'b0;
            endpoint_select_stage1 <= 4'b0;
            transfer_ready_stage1 <= 1'b0;
            tx_data_stage1 <= {DATA_WIDTH{1'b0}};
            pipe_valid_stage1 <= 1'b0;
            
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                frame_diff[i] <= 11'b0;
            end
        end else begin
            // Register inputs
            sof_received_stage1 <= sof_received;
            frame_number_stage1 <= frame_number;
            endpoint_select_stage1 <= endpoint_select;
            transfer_ready_stage1 <= transfer_ready;
            tx_data_stage1 <= tx_data;
            
            // Pipeline valid signal
            pipe_valid_stage1 <= sof_received;
            
            // Register pre-calculated frame differences
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                frame_diff[i] <= frame_diff_wire[i];
            end
        end
    end
    
    // Stage 2: Interval checking and endpoint processing
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            sof_received_stage2 <= 1'b0;
            frame_number_stage2 <= 11'b0;
            endpoint_select_stage2 <= 4'b0;
            transfer_ready_stage2 <= 1'b0;
            tx_data_stage2 <= {DATA_WIDTH{1'b0}};
            pipe_valid_stage2 <= 1'b0;
            interval_check_stage1 <= {NUM_ENDPOINTS{1'b0}};
            endpoints_to_process_stage1 <= {NUM_ENDPOINTS{1'b0}};
        end else begin
            // Forward pipeline registers
            sof_received_stage2 <= sof_received_stage1;
            frame_number_stage2 <= frame_number_stage1;
            endpoint_select_stage2 <= endpoint_select_stage1;
            transfer_ready_stage2 <= transfer_ready_stage1;
            tx_data_stage2 <= tx_data_stage1;
            pipe_valid_stage2 <= pipe_valid_stage1;
            
            // Register pre-calculated interval checks
            interval_check_stage1 <= interval_check_wire;
            
            // Mark endpoints that need processing
            endpoints_to_process_stage1 <= pipe_valid_stage1 && sof_received_stage1 ? 
                                          interval_check_wire : {NUM_ENDPOINTS{1'b0}};
        end
    end
    
    // Stage 3: Output generation and state update
    always @(posedge clock or negedge reset_b) begin
        if (!reset_b) begin
            transfer_active <= 1'b0;
            bandwidth_state <= IDLE;
            endpoint_status <= {NUM_ENDPOINTS{1'b0}};
            pipe_valid_stage3 <= 1'b0;
            interval_check_stage2 <= {NUM_ENDPOINTS{1'b0}};
            endpoints_to_process_stage2 <= {NUM_ENDPOINTS{1'b0}};
            rx_data <= {DATA_WIDTH{1'b0}};
            
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                interval[i] <= 3'd1;         // Default interval of 1 frame
                last_frame[i] <= 11'h7FF;    // Invalid frame number
            end
        end else begin
            // Forward pipeline signals
            pipe_valid_stage3 <= pipe_valid_stage2;
            interval_check_stage2 <= interval_check_stage1;
            endpoints_to_process_stage2 <= endpoints_to_process_stage1;
            
            // Update endpoint status based on interval check
            if (pipe_valid_stage2 && sof_received_stage2) begin
                endpoint_status <= endpoint_status | endpoints_to_process_stage1;
                
                // Update last_frame for endpoints that are being processed
                for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                    if (endpoints_to_process_stage1[i]) begin
                        last_frame[i] <= frame_number_stage2;
                    end
                end
                
                // Handle bandwidth state transitions
                case (bandwidth_state)
                    IDLE: begin
                        if (|endpoints_to_process_stage1) 
                            bandwidth_state <= RESERVED;
                    end
                    default: bandwidth_state <= bandwidth_state; // No change
                endcase
            end
            
            // Handle transfer activation based on endpoint selection and ready signal
            if (transfer_ready_stage2 && endpoint_select_stage2 < NUM_ENDPOINTS && 
                endpoint_status[endpoint_select_stage2]) begin
                transfer_active <= 1'b1;
                rx_data <= tx_data_stage2;  // Process data transfer
                endpoint_status[endpoint_select_stage2] <= 1'b0;  // Clear status after handling
                
                if (bandwidth_state == RESERVED) begin
                    bandwidth_state <= ACTIVE;
                end
            end else begin
                transfer_active <= 1'b0;
                
                // Check if all endpoints are processed - optimization for zero check
                case (bandwidth_state)
                    ACTIVE: begin
                        if (endpoint_status == {NUM_ENDPOINTS{1'b0}})
                            bandwidth_state <= COMPLETE;
                    end
                    COMPLETE: bandwidth_state <= IDLE;
                    default: bandwidth_state <= bandwidth_state; // No change
                endcase
            end
        end
    end
endmodule