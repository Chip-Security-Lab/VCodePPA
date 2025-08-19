//SystemVerilog - IEEE 1364-2005
module usb_speed_detector(
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // USB Interface
    input wire dp,
    input wire dm
);
    // State definitions
    localparam IDLE = 2'b00;
    localparam WAIT_STABLE = 2'b01;
    localparam DETECT = 2'b10;
    localparam COMPLETE = 2'b11;
    
    // Pipeline stage registers
    reg [9:0] stability_counter;
    reg [9:0] stability_counter_stage1;
    reg [9:0] stability_counter_stage2;
    
    reg dp_stage1, dp_stage2, dp_stage3;
    reg dm_stage1, dm_stage2, dm_stage3;
    reg prev_dp, prev_dm;
    reg dp_stable_stage1, dp_stable_stage2;
    reg dm_stable_stage1, dm_stable_stage2;
    
    reg detect_en_stage1, detect_en_stage2, detect_en_stage3;
    reg [1:0] detection_state_stage1, detection_state_stage2;
    
    reg counter_threshold_met_stage1;
    reg counter_inc_stage1, counter_inc_stage2;
    reg counter_reset_stage1, counter_reset_stage2;
    
    // Internal status registers
    reg low_speed;
    reg full_speed;
    reg no_device;
    reg chirp_detected;
    reg [1:0] detection_state;
    reg detect_en;
    
    // AXI4-Lite register address map
    localparam CTRL_REG_ADDR       = 8'h00; // Control register (detect_en)
    localparam STATUS_REG_ADDR     = 8'h04; // Status register (combined status)
    
    // AXI4-Lite internal signals
    reg [31:0] axi_awaddr, axi_araddr;
    reg write_en, read_en;
    reg [31:0] reg_data_out;
    
    // AXI Write Address Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            axi_awaddr <= 32'b0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b1;
                axi_awaddr <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end
    
    // AXI Write Data Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
            write_en <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                s_axi_wready <= 1'b1;
                write_en <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
                write_en <= 1'b0;
            end
        end
    end
    
    // AXI Write Response Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b0;
        end else begin
            if (write_en && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00; // OKAY response
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // AXI Read Address Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            axi_araddr <= 32'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                axi_araddr <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end
    
    // AXI Read Data Channel
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b0;
            read_en <= 1'b0;
        end else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00; // OKAY response
                read_en <= 1'b1;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
                read_en <= 1'b0;
            end
        end
    end
    
    // Register Read Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_data_out <= 32'b0;
        end else if (read_en) begin
            case (axi_araddr[7:0])
                CTRL_REG_ADDR: reg_data_out <= {31'b0, detect_en};
                STATUS_REG_ADDR: reg_data_out <= {26'b0, detection_state, chirp_detected, no_device, full_speed, low_speed};
                default: reg_data_out <= 32'b0;
            endcase
        end
    end
    
    // Drive read data output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rdata <= 32'b0;
        end else if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rdata <= reg_data_out;
        end
    end
    
    // Register Write Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detect_en <= 1'b0;
        end else if (write_en) begin
            case (axi_awaddr[7:0])
                CTRL_REG_ADDR: detect_en <= s_axi_wdata[0];
                default: begin end
            endcase
        end
    end
    
    // First pipeline stage - Input registration and stability detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_stage1 <= 1'b0;
            dm_stage1 <= 1'b0;
            prev_dp <= 1'b0;
            prev_dm <= 1'b0;
            dp_stable_stage1 <= 1'b0;
            dm_stable_stage1 <= 1'b0;
            detect_en_stage1 <= 1'b0;
            detection_state_stage1 <= IDLE;
        end else begin
            dp_stage1 <= dp;
            dm_stage1 <= dm;
            prev_dp <= dp_stage1;
            prev_dm <= dm_stage1;
            dp_stable_stage1 <= (dp_stage1 == prev_dp);
            dm_stable_stage1 <= (dm_stage1 == prev_dm);
            detect_en_stage1 <= detect_en;
            detection_state_stage1 <= detection_state;
        end
    end
    
    // Second pipeline stage - Counter logic and state transitions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_stage2 <= 1'b0;
            dm_stage2 <= 1'b0;
            dp_stable_stage2 <= 1'b0;
            dm_stable_stage2 <= 1'b0;
            detect_en_stage2 <= 1'b0;
            detection_state_stage2 <= IDLE;
            counter_threshold_met_stage1 <= 1'b0;
            counter_inc_stage1 <= 1'b0;
            counter_reset_stage1 <= 1'b0;
            stability_counter_stage1 <= 10'd0;
        end else begin
            dp_stage2 <= dp_stage1;
            dm_stage2 <= dm_stage1;
            dp_stable_stage2 <= dp_stable_stage1;
            dm_stable_stage2 <= dm_stable_stage1;
            detect_en_stage2 <= detect_en_stage1;
            detection_state_stage2 <= detection_state_stage1;
            
            // Counter logic in stage 2
            counter_threshold_met_stage1 <= (stability_counter >= 10'd500);
            counter_inc_stage1 <= (dp_stable_stage1 && dm_stable_stage1 && 
                                 detection_state_stage1 == WAIT_STABLE);
            counter_reset_stage1 <= (!dp_stable_stage1 || !dm_stable_stage1) && 
                                  detection_state_stage1 == WAIT_STABLE;
            
            // Update counter value
            stability_counter_stage1 <= stability_counter;
        end
    end
    
    // Third pipeline stage - State logic and outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dp_stage3 <= 1'b0;
            dm_stage3 <= 1'b0;
            detect_en_stage3 <= 1'b0;
            counter_inc_stage2 <= 1'b0;
            counter_reset_stage2 <= 1'b0;
            stability_counter_stage2 <= 10'd0;
        end else begin
            dp_stage3 <= dp_stage2;
            dm_stage3 <= dm_stage2;
            detect_en_stage3 <= detect_en_stage2;
            counter_inc_stage2 <= counter_inc_stage1;
            counter_reset_stage2 <= counter_reset_stage1;
            stability_counter_stage2 <= stability_counter_stage1;
        end
    end
    
    // Final stage - Counter update and state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detection_state <= IDLE;
            low_speed <= 1'b0;
            full_speed <= 1'b0;
            no_device <= 1'b1;
            chirp_detected <= 1'b0;
            stability_counter <= 10'd0;
        end else begin
            // Counter update logic
            if (counter_reset_stage2)
                stability_counter <= 10'd0;
            else if (counter_inc_stage2)
                stability_counter <= stability_counter + 10'd1;
                
            // State machine with pipelined inputs
            case (detection_state)
                IDLE: begin
                    if (detect_en_stage3) begin
                        detection_state <= WAIT_STABLE;
                        stability_counter <= 10'd0;
                    end
                end
                
                WAIT_STABLE: begin
                    if (dp_stable_stage2 && dm_stable_stage2) begin
                        if (counter_threshold_met_stage1)
                            detection_state <= DETECT;
                    end
                end
                
                DETECT: begin
                    no_device <= !(dp_stage3 || dm_stage3);
                    full_speed <= dp_stage3 && !dm_stage3;
                    low_speed <= !dp_stage3 && dm_stage3;
                    chirp_detected <= dp_stage3 && dm_stage3;
                    detection_state <= COMPLETE;
                end
                
                COMPLETE: begin
                    if (!detect_en_stage3)
                        detection_state <= IDLE;
                end
            endcase
        end
    end
endmodule