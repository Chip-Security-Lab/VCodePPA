//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module usb_device_state_machine(
    // Clock and reset
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream slave interface
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tlast,
    
    // AXI-Stream master interface
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tlast
);
    // USB device states with one-cold encoding
    localparam POWERED    = 4'b1110;
    localparam DEFAULT    = 4'b1101;
    localparam ADDRESS    = 4'b1011;
    localparam CONFIGURED = 4'b0111;
    localparam SUSPENDED  = 4'b1110; // Same as POWERED but with context
    
    // Internal control signals extracted from s_axis_tdata
    // Pipeline stage 1: Extract and register control signals
    reg [31:0] s_axis_tdata_stage1;
    reg s_axis_tvalid_stage1;
    reg s_axis_tlast_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axis_tdata_stage1 <= 32'h0;
            s_axis_tvalid_stage1 <= 1'b0;
            s_axis_tlast_stage1 <= 1'b0;
        end else if (s_axis_tvalid && s_axis_tready) begin
            s_axis_tdata_stage1 <= s_axis_tdata;
            s_axis_tvalid_stage1 <= s_axis_tvalid;
            s_axis_tlast_stage1 <= s_axis_tlast;
        end else if (!s_data_received_stage2) begin
            s_axis_tvalid_stage1 <= 1'b0;
        end
    end
    
    // Pipeline stage 2: Decode control signals
    reg bus_reset_detected_stage2;
    reg setup_received_stage2;
    reg address_assigned_stage2;
    reg configuration_set_stage2;
    reg suspend_detected_stage2;
    reg resume_detected_stage2;
    reg self_powered_in_stage2;
    reg s_axis_tvalid_stage2;
    reg s_data_received_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bus_reset_detected_stage2 <= 1'b0;
            setup_received_stage2 <= 1'b0;
            address_assigned_stage2 <= 1'b0;
            configuration_set_stage2 <= 1'b0;
            suspend_detected_stage2 <= 1'b0;
            resume_detected_stage2 <= 1'b0;
            self_powered_in_stage2 <= 1'b0;
            s_axis_tvalid_stage2 <= 1'b0;
            s_data_received_stage2 <= 1'b0;
        end else begin
            if (s_axis_tvalid_stage1) begin
                bus_reset_detected_stage2 <= s_axis_tdata_stage1[0];
                setup_received_stage2 <= s_axis_tdata_stage1[1];
                address_assigned_stage2 <= s_axis_tdata_stage1[2];
                configuration_set_stage2 <= s_axis_tdata_stage1[3];
                suspend_detected_stage2 <= s_axis_tdata_stage1[4];
                resume_detected_stage2 <= s_axis_tdata_stage1[5];
                self_powered_in_stage2 <= s_axis_tdata_stage1[6];
                s_axis_tvalid_stage2 <= s_axis_tvalid_stage1;
                s_data_received_stage2 <= 1'b1;
            end else if (state_updated_stage4 && s_data_received_stage2) begin
                s_data_received_stage2 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 3: State decision logic
    reg [3:0] device_state_stage3;
    reg [3:0] prev_state_stage3;
    reg remote_wakeup_enabled_stage3;
    reg self_powered_stage3;
    reg [7:0] interface_alternate_stage3;
    reg [3:0] next_state_stage3;
    reg update_remote_wakeup_stage3;
    reg update_interface_alternate_stage3;
    reg s_data_received_stage3;
    reg s_axis_tvalid_stage3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            device_state_stage3 <= POWERED;
            prev_state_stage3 <= POWERED;
            remote_wakeup_enabled_stage3 <= 1'b0;
            self_powered_stage3 <= 1'b0;
            interface_alternate_stage3 <= 8'h00;
            next_state_stage3 <= POWERED;
            update_remote_wakeup_stage3 <= 1'b0;
            update_interface_alternate_stage3 <= 1'b0;
            s_data_received_stage3 <= 1'b0;
            s_axis_tvalid_stage3 <= 1'b0;
        end else begin
            // Pass through current state values
            device_state_stage3 <= device_state_stage4;
            prev_state_stage3 <= prev_state_stage4;
            remote_wakeup_enabled_stage3 <= remote_wakeup_enabled_stage4;
            self_powered_stage3 <= self_powered_stage4;
            interface_alternate_stage3 <= interface_alternate_stage4;
            s_data_received_stage3 <= s_data_received_stage2;
            s_axis_tvalid_stage3 <= s_axis_tvalid_stage2;
            
            // Next state decision logic - split from state update logic
            if (s_axis_tvalid_stage2 && s_data_received_stage2) begin
                if (bus_reset_detected_stage2) begin
                    next_state_stage3 <= DEFAULT;
                    update_remote_wakeup_stage3 <= 1'b1;
                    update_interface_alternate_stage3 <= 1'b1;
                end else if (suspend_detected_stage2 && device_state_stage4 != SUSPENDED) begin
                    next_state_stage3 <= SUSPENDED;
                    update_remote_wakeup_stage3 <= 1'b0;
                    update_interface_alternate_stage3 <= 1'b0;
                end else if (resume_detected_stage2 && device_state_stage4 == SUSPENDED) begin
                    next_state_stage3 <= prev_state_stage4;
                    update_remote_wakeup_stage3 <= 1'b0;
                    update_interface_alternate_stage3 <= 1'b0;
                end else begin
                    case (device_state_stage4)
                        DEFAULT: begin
                            next_state_stage3 <= address_assigned_stage2 ? ADDRESS : device_state_stage4;
                            update_remote_wakeup_stage3 <= 1'b0;
                            update_interface_alternate_stage3 <= 1'b0;
                        end
                        ADDRESS: begin
                            next_state_stage3 <= configuration_set_stage2 ? CONFIGURED : device_state_stage4;
                            update_remote_wakeup_stage3 <= 1'b0;
                            update_interface_alternate_stage3 <= 1'b0;
                        end
                        CONFIGURED: begin
                            next_state_stage3 <= !configuration_set_stage2 ? ADDRESS : device_state_stage4;
                            update_remote_wakeup_stage3 <= 1'b0;
                            update_interface_alternate_stage3 <= 1'b0;
                        end
                        default: begin
                            next_state_stage3 <= device_state_stage4;
                            update_remote_wakeup_stage3 <= 1'b0;
                            update_interface_alternate_stage3 <= 1'b0;
                        end
                    endcase
                end
            end else begin
                next_state_stage3 <= device_state_stage4;
                update_remote_wakeup_stage3 <= 1'b0;
                update_interface_alternate_stage3 <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 4: State update
    reg [3:0] device_state_stage4;
    reg [3:0] prev_state_stage4;
    reg remote_wakeup_enabled_stage4;
    reg self_powered_stage4;
    reg [7:0] interface_alternate_stage4;
    reg state_updated_stage4;
    reg [31:0] m_axis_tdata_stage4;
    reg m_axis_tlast_stage4;
    reg output_valid_stage4;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            device_state_stage4 <= POWERED;
            prev_state_stage4 <= POWERED;
            remote_wakeup_enabled_stage4 <= 1'b0;
            self_powered_stage4 <= 1'b0;
            interface_alternate_stage4 <= 8'h00;
            state_updated_stage4 <= 1'b0;
            output_valid_stage4 <= 1'b0;
        end else begin
            // State update based on stage 3 decisions
            if (s_axis_tvalid_stage3 && s_data_received_stage3) begin
                prev_state_stage4 <= device_state_stage4;
                device_state_stage4 <= next_state_stage3;
                
                if (update_remote_wakeup_stage3)
                    remote_wakeup_enabled_stage4 <= 1'b0;
                
                if (update_interface_alternate_stage3)
                    interface_alternate_stage4 <= 8'h00;
                
                // Update device configuration based on input data
                self_powered_stage4 <= self_powered_in_stage2;
                
                state_updated_stage4 <= 1'b1;
                output_valid_stage4 <= 1'b1;
            end else if (m_axis_tvalid && m_axis_tready) begin
                state_updated_stage4 <= 1'b0;
                output_valid_stage4 <= 1'b0;
            end
            
            // Format output data
            m_axis_tdata_stage4 <= {16'h0000, interface_alternate_stage4, 4'h0, 
                                  self_powered_stage4, remote_wakeup_enabled_stage4, 
                                  device_state_stage4};
            m_axis_tlast_stage4 <= 1'b1; // Last transfer in sequence
        end
    end
    
    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata <= 32'h0;
            m_axis_tlast <= 1'b0;
        end else begin
            if (output_valid_stage4 && !m_axis_tvalid) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tdata <= m_axis_tdata_stage4;
                m_axis_tlast <= m_axis_tlast_stage4;
            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end
    
    // Always ready to receive data
    assign s_axis_tready = 1'b1;
    
endmodule