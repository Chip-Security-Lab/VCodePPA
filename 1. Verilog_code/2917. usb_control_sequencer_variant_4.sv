//SystemVerilog
module usb_control_sequencer(
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input  wire [7:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // Write Response Channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // Read Address Channel
    input  wire [7:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // Read Data Channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // Internal registers for control logic
    reg [2:0]  control_state;
    reg        need_data_out;
    reg        need_data_in;
    reg        need_status_in;
    reg        need_status_out;
    reg        transfer_complete;

    // Control signals from original design
    reg        setup_received;
    reg [7:0]  bmRequestType;
    reg [7:0]  bRequest;
    reg [15:0] wValue;
    reg [15:0] wIndex;
    reg [15:0] wLength;
    reg        data_out_received;
    reg        data_in_sent;
    reg        status_phase_done;

    // Control transfer states - clearly defined state encoding
    localparam [2:0] IDLE        = 3'd0;
    localparam [2:0] SETUP       = 3'd1;
    localparam [2:0] DATA_OUT    = 3'd2;
    localparam [2:0] DATA_IN     = 3'd3;
    localparam [2:0] STATUS_OUT  = 3'd4;
    localparam [2:0] STATUS_IN   = 3'd5;
    localparam [2:0] COMPLETE    = 3'd6;
    
    // First stage input registers
    reg        setup_received_r;
    reg [7:0]  bmRequestType_r;
    reg [15:0] wLength_r;
    
    // First stage processing outputs
    reg        setup_valid_r;
    reg        is_host_to_device_r;
    reg        has_data_phase_r;
    
    // Second stage registers
    reg        need_data_out_next;
    reg        need_data_in_next;
    reg        need_status_in_next;
    reg        need_status_out_next;

    // AXI4-Lite specific registers
    reg [7:0]  axi_read_addr;
    reg [7:0]  axi_write_addr;
    reg        write_en;
    reg        read_en;
    
    // Memory-mapped register addresses
    localparam REG_SETUP_RECEIVED      = 8'h00;
    localparam REG_BMREQUEST_TYPE      = 8'h04;
    localparam REG_BREQUEST            = 8'h08;
    localparam REG_WVALUE              = 8'h0C;
    localparam REG_WINDEX              = 8'h10;
    localparam REG_WLENGTH             = 8'h14;
    localparam REG_DATA_OUT_RECEIVED   = 8'h18;
    localparam REG_DATA_IN_SENT        = 8'h1C;
    localparam REG_STATUS_PHASE_DONE   = 8'h20;
    localparam REG_CONTROL_STATE       = 8'h24;
    localparam REG_STATUS_FLAGS        = 8'h28;

    // AXI4-Lite Write Address Channel Logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            axi_write_addr <= 8'h0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b1;
                axi_write_addr <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end

    // AXI4-Lite Write Data Channel Logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            write_en <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid && s_axi_awready) begin
                s_axi_wready <= 1'b1;
                write_en <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
                write_en <= 1'b0;
            end
        end
    end

    // AXI4-Lite Write Response Channel Logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00; // OKAY response
        end else begin
            if (write_en) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00;
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Address Channel Logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            axi_read_addr <= 8'h0;
            read_en <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                axi_read_addr <= s_axi_araddr;
                read_en <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
                read_en <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Data Channel Logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00; // OKAY response
            s_axi_rdata <= 32'h0;
        end else begin
            if (read_en) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00;
                
                case (axi_read_addr)
                    REG_CONTROL_STATE: 
                        s_axi_rdata <= {29'h0, control_state};
                    REG_STATUS_FLAGS: 
                        s_axi_rdata <= {27'h0, transfer_complete, need_status_out, need_status_in, need_data_in, need_data_out};
                    REG_BMREQUEST_TYPE: 
                        s_axi_rdata <= {24'h0, bmRequestType};
                    REG_BREQUEST: 
                        s_axi_rdata <= {24'h0, bRequest};
                    REG_WVALUE: 
                        s_axi_rdata <= {16'h0, wValue};
                    REG_WINDEX: 
                        s_axi_rdata <= {16'h0, wIndex};
                    REG_WLENGTH: 
                        s_axi_rdata <= {16'h0, wLength};
                    default:
                        s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // Write to registers based on AXI writes
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            setup_received <= 1'b0;
            bmRequestType <= 8'h0;
            bRequest <= 8'h0;
            wValue <= 16'h0;
            wIndex <= 16'h0;
            wLength <= 16'h0;
            data_out_received <= 1'b0;
            data_in_sent <= 1'b0;
            status_phase_done <= 1'b0;
        end else begin
            // Auto-clear the strobe signals after they're processed
            setup_received <= 1'b0;
            data_out_received <= 1'b0;
            data_in_sent <= 1'b0;
            status_phase_done <= 1'b0;
            
            if (write_en && s_axi_wvalid) begin
                case (axi_write_addr)
                    REG_SETUP_RECEIVED: 
                        setup_received <= s_axi_wdata[0];
                    REG_BMREQUEST_TYPE: 
                        bmRequestType <= s_axi_wdata[7:0];
                    REG_BREQUEST: 
                        bRequest <= s_axi_wdata[7:0];
                    REG_WVALUE: 
                        wValue <= s_axi_wdata[15:0];
                    REG_WINDEX: 
                        wIndex <= s_axi_wdata[15:0];
                    REG_WLENGTH: 
                        wLength <= s_axi_wdata[15:0];
                    REG_DATA_OUT_RECEIVED: 
                        data_out_received <= s_axi_wdata[0];
                    REG_DATA_IN_SENT: 
                        data_in_sent <= s_axi_wdata[0];
                    REG_STATUS_PHASE_DONE: 
                        status_phase_done <= s_axi_wdata[0];
                    default: begin
                        // No action for unrecognized address
                    end
                endcase
            end
        end
    end
    
    // First stage input registration and processing
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            setup_received_r <= 1'b0;
            bmRequestType_r <= 8'h0;
            wLength_r <= 16'h0;
        end else begin
            setup_received_r <= setup_received;
            bmRequestType_r <= bmRequestType;
            wLength_r <= wLength;
        end
    end
    
    // Second stage processing
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            setup_valid_r <= 1'b0;
            is_host_to_device_r <= 1'b0;
            has_data_phase_r <= 1'b0;
        end else begin
            setup_valid_r <= setup_received_r;
            is_host_to_device_r <= (bmRequestType_r[7] == 1'b0);
            has_data_phase_r <= (wLength_r > 16'd0);
        end
    end
    
    // Control signal generation - moved after combinational logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            need_data_out_next <= 1'b0;
            need_data_in_next <= 1'b0;
            need_status_in_next <= 1'b0;
            need_status_out_next <= 1'b0;
        end else begin
            if (setup_valid_r) begin
                need_data_out_next <= is_host_to_device_r && has_data_phase_r;
                need_data_in_next <= !is_host_to_device_r && has_data_phase_r;
                need_status_in_next <= is_host_to_device_r;
                need_status_out_next <= !is_host_to_device_r;
            end else begin
                need_data_out_next <= 1'b0;
                need_data_in_next <= 1'b0;
                need_status_in_next <= 1'b0;
                need_status_out_next <= 1'b0;
            end
        end
    end
    
    // Main state machine with registered outputs
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            control_state <= IDLE;
            need_data_out <= 1'b0;
            need_data_in <= 1'b0;
            need_status_in <= 1'b0;
            need_status_out <= 1'b0;
            transfer_complete <= 1'b0;
        end else begin
            // Default values for outputs
            need_data_out <= need_data_out;
            need_data_in <= need_data_in;
            need_status_in <= need_status_in;
            need_status_out <= need_status_out;
            transfer_complete <= transfer_complete;
            
            case (control_state)
                IDLE: begin
                    // Reset control signals
                    transfer_complete <= 1'b0;
                    
                    // Setup phase detection (using pipelined setup info)
                    if (setup_valid_r) begin
                        control_state <= SETUP;
                        need_data_out <= need_data_out_next;
                        need_data_in <= need_data_in_next;
                        need_status_in <= need_status_in_next;
                        need_status_out <= need_status_out_next;
                    end else begin
                        need_data_out <= 1'b0;
                        need_data_in <= 1'b0;
                        need_status_in <= 1'b0;
                        need_status_out <= 1'b0;
                    end
                end
                
                SETUP: begin
                    // Data/Status phase transition logic
                    if (need_data_out) 
                        control_state <= DATA_OUT;
                    else if (need_data_in) 
                        control_state <= DATA_IN;
                    else if (need_status_in) 
                        control_state <= STATUS_IN;
                    else if (need_status_out) 
                        control_state <= STATUS_OUT;
                end
                
                DATA_OUT: begin
                    // Data-OUT phase handling
                    if (data_out_received) begin
                        need_data_out <= 1'b0;
                        control_state <= (need_status_in) ? STATUS_IN : COMPLETE;
                    end
                end
                
                DATA_IN: begin
                    // Data-IN phase handling
                    if (data_in_sent) begin
                        need_data_in <= 1'b0;
                        control_state <= (need_status_out) ? STATUS_OUT : COMPLETE;
                    end
                end
                
                STATUS_OUT: begin
                    // Status-OUT phase handling
                    if (status_phase_done) begin
                        need_status_out <= 1'b0;
                        control_state <= COMPLETE;
                    end
                end
                
                STATUS_IN: begin
                    // Status-IN phase handling
                    if (status_phase_done) begin
                        need_status_in <= 1'b0;
                        control_state <= COMPLETE;
                    end
                end
                
                COMPLETE: begin
                    // Transfer completion signaling
                    transfer_complete <= 1'b1;
                    control_state <= IDLE;
                end
                
                default: begin
                    // Safety state - recover to IDLE
                    control_state <= IDLE;
                end
            endcase
        end
    end
endmodule