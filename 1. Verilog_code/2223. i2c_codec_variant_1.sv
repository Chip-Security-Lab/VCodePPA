//SystemVerilog
module i2c_codec_axi (
    // Clock and reset
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite slave interface
    // Write address channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write data channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write response channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read address channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid, 
    output reg s_axil_arready,
    
    // Read data channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // I2C interface
    inout wire sda,
    output reg scl
);
    // Register address offsets - 使用4位参数以减少比较器逻辑
    localparam CTRL_REG      = 4'h0; // Control register: start_xfer, rw
    localparam ADDR_REG      = 4'h4; // I2C slave address
    localparam WDATA_REG     = 4'h8; // Write data register
    localparam RDATA_REG     = 4'hC; // Read data register
    localparam STATUS_REG    = 4'h10; // Status register: busy, done
    
    // Internal registers
    reg start_xfer, rw;
    reg [6:0] addr;
    reg [7:0] wr_data;
    reg [7:0] rd_data;
    reg busy, done;
    
    // AXI4-Lite transaction handling - 使用4位地址减少比较逻辑
    reg [3:0] axi_write_addr;
    reg [31:0] axi_write_data;
    reg write_en;
    
    reg [3:0] axi_read_addr;
    reg read_en;
    
    // I2C state machine parameters - 使用3个比特编码8个状态
    localparam [2:0] 
        IDLE  = 3'h0,
        START = 3'h1, 
        ADDR  = 3'h2, 
        RW    = 3'h3, 
        ACK1  = 3'h4, 
        DATA  = 3'h5, 
        ACK2  = 3'h6, 
        STOP  = 3'h7;
        
    reg [2:0] state, next;
    reg [3:0] bit_cnt;
    reg [7:0] shift_reg;
    reg sda_out, sda_oe;
    
    // I2C SDA control - 三态控制
    assign sda = sda_oe ? sda_out : 1'bz;
    
    // 提前计算状态转换条件,减少路径深度
    wire addr_complete = (bit_cnt == 7);
    wire data_complete = (bit_cnt > 8);
    wire in_idle_state = (state == IDLE);
    
    // 预解码寄存器地址以减少路径延迟
    wire is_ctrl_reg   = (axi_write_addr == CTRL_REG);
    wire is_addr_reg   = (axi_write_addr == ADDR_REG);
    wire is_wdata_reg  = (axi_write_addr == WDATA_REG);
    
    // 读寄存器预解码
    wire read_ctrl_reg   = (axi_read_addr == CTRL_REG);
    wire read_addr_reg   = (axi_read_addr == ADDR_REG);
    wire read_wdata_reg  = (axi_read_addr == WDATA_REG);
    wire read_rdata_reg  = (axi_read_addr == RDATA_REG);
    wire read_status_reg = (axi_read_addr == STATUS_REG);
    
    // I2C操作标志
    wire is_write_op = (rw == 1'b0);
    wire is_read_op = !is_write_op;
    
    // 时钟边沿控制逻辑
    wire scl_low = (scl == 1'b0);
    wire scl_high = !scl_low;
    
    // Write address channel handler
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
            axi_write_addr <= 4'h0;
        end else begin
            if (s_axil_awvalid && !s_axil_awready) begin
                s_axil_awready <= 1'b1;
                axi_write_addr <= s_axil_awaddr[5:2]; // Capture the word address
            end else begin
                s_axil_awready <= 1'b0;
            end
        end
    end
    
    // Write data channel handler
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_wready <= 1'b0;
            axi_write_data <= 32'h0;
            write_en <= 1'b0;
        end else begin
            if (s_axil_wvalid && !s_axil_wready) begin
                s_axil_wready <= 1'b1;
                axi_write_data <= s_axil_wdata;
                write_en <= 1'b1;
            end else begin
                s_axil_wready <= 1'b0;
                write_en <= 1'b0;
            end
        end
    end
    
    // Write response channel handler - 简化逻辑
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00; // OKAY response
        end else begin
            if (write_en) 
                s_axil_bvalid <= 1'b1;
            else if (s_axil_bready && s_axil_bvalid)
                s_axil_bvalid <= 1'b0;
        end
    end
    
    // Read address channel handler
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            axi_read_addr <= 4'h0;
            read_en <= 1'b0;
        end else begin
            if (s_axil_arvalid && !s_axil_arready) begin
                s_axil_arready <= 1'b1;
                axi_read_addr <= s_axil_araddr[5:2]; // Capture the word address
                read_en <= 1'b1;
            end else begin
                s_axil_arready <= 1'b0;
                read_en <= 1'b0;
            end
        end
    end
    
    // 预计算和注册读数据值，减少读响应路径
    reg [31:0] read_data_mux;
    
    // 读数据预选择逻辑 - 拆分大型多路复用器
    always @(posedge aclk) begin
        if (read_en) begin
            if (read_ctrl_reg)
                read_data_mux <= {30'h0, rw, start_xfer};
            else if (read_addr_reg)
                read_data_mux <= {25'h0, addr};
            else if (read_wdata_reg)
                read_data_mux <= {24'h0, wr_data};
            else if (read_rdata_reg)
                read_data_mux <= {24'h0, rd_data};
            else if (read_status_reg)
                read_data_mux <= {30'h0, done, busy};
            else
                read_data_mux <= 32'h0;
        end
    end
    
    // Read data channel handler - 使用预选择的数据减少组合路径
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00; // OKAY response
            s_axil_rdata <= 32'h0;
        end else begin
            if (read_en) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rdata <= read_data_mux;
            end else if (s_axil_rready && s_axil_rvalid) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end
    
    // Register write handler - 使用预解码的寄存器地址
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            start_xfer <= 1'b0;
            rw <= 1'b0;
            addr <= 7'h0;
            wr_data <= 8'h0;
        end else begin
            // 默认自动清除start_xfer
            if (in_idle_state)
                start_xfer <= 1'b0;
                
            if (write_en) begin
                if (is_ctrl_reg) begin
                    start_xfer <= axi_write_data[0];
                    rw <= axi_write_data[1];
                end else if (is_addr_reg)
                    addr <= axi_write_data[6:0];
                else if (is_wdata_reg)
                    wr_data <= axi_write_data[7:0];
            end
        end
    end
    
    // I2C state machine - 拆分大型状态机以减少关键路径
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin 
            state <= IDLE; 
            bit_cnt <= 0; 
            scl <= 1'b1;
            busy <= 1'b0;
            done <= 1'b0;
            sda_oe <= 1'b0;
            sda_out <= 1'b1;
            shift_reg <= 8'h0;
            rd_data <= 8'h0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    scl <= 1'b1;
                    sda_oe <= 1'b1;
                    sda_out <= 1'b1;
                    bit_cnt <= 0;
                    
                    if (start_xfer) begin
                        busy <= 1'b1;
                        done <= 1'b0;
                    end
                end
                
                START: begin
                    sda_out <= 1'b0; // Start condition: SDA goes low while SCL is high
                    scl <= 1'b1;
                    bit_cnt <= 0;
                end
                
                ADDR: begin
                    if (bit_cnt == 0) begin
                        shift_reg <= {addr, 1'b0}; // Prepare addr + rw bit
                        scl <= 1'b0;
                        bit_cnt <= bit_cnt + 1'b1;
                    end else begin
                        if (scl_low) begin
                            sda_out <= shift_reg[7];
                            shift_reg <= {shift_reg[6:0], 1'b0};
                            scl <= 1'b1;
                        end else begin
                            scl <= 1'b0;
                            if (bit_cnt < 7)  // 避免比较器延迟
                                bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end
                
                RW: begin
                    if (scl_low) begin
                        sda_out <= rw;
                        scl <= 1'b1;
                    end else begin
                        scl <= 1'b0;
                    end
                end
                
                ACK1: begin
                    if (scl_low) begin
                        sda_oe <= 1'b0; // Release SDA for slave ACK
                        scl <= 1'b1;
                    end else begin
                        scl <= 1'b0;
                        sda_oe <= 1'b1; // Take control of SDA again
                    end
                end
                
                DATA: begin
                    if (bit_cnt == 0) begin
                        shift_reg <= is_write_op ? wr_data : 8'h0;
                        bit_cnt <= bit_cnt + 1'b1;
                    end else if (bit_cnt <= 8) begin
                        if (is_write_op) begin
                            if (scl_low) begin
                                sda_out <= shift_reg[7];
                                shift_reg <= {shift_reg[6:0], 1'b0};
                                scl <= 1'b1;
                            end else begin
                                scl <= 1'b0;
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end else begin // Read operation
                            if (scl_low) begin
                                sda_oe <= 1'b0; // Release SDA for slave data
                                scl <= 1'b1;
                            end else begin
                                shift_reg <= {shift_reg[6:0], sda}; // Sample SDA
                                scl <= 1'b0;
                                bit_cnt <= bit_cnt + 1'b1;
                            end
                        end
                    end
                end
                
                ACK2: begin
                    if (is_write_op) begin
                        if (scl_low) begin
                            sda_oe <= 1'b0; // Release SDA for slave ACK
                            scl <= 1'b1;
                        end else begin
                            scl <= 1'b0;
                            sda_oe <= 1'b1; // Take control of SDA again
                        end
                    end else begin // Read operation
                        if (scl_low) begin
                            sda_out <= 1'b0; // Master ACK
                            sda_oe <= 1'b1;
                            rd_data <= shift_reg; // Store read data
                            scl <= 1'b1;
                        end else begin
                            scl <= 1'b0;
                        end
                    end
                end
                
                STOP: begin
                    if (scl_low) begin
                        sda_out <= 1'b0;
                        scl <= 1'b1;
                    end else begin
                        sda_out <= 1'b1; // Stop condition: SDA goes high while SCL is high
                        busy <= 1'b0;
                        done <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // 优化状态转换逻辑 - 使用前面计算的条件信号
    always @(*) begin
        case (state)
            IDLE:  next = start_xfer ? START : IDLE;
            START: next = ADDR;
            ADDR:  next = addr_complete ? RW : ADDR;
            RW:    next = ACK1;
            ACK1:  next = DATA;
            DATA:  next = data_complete ? ACK2 : DATA;
            ACK2:  next = STOP;
            STOP:  next = IDLE;
            default: next = IDLE;
        endcase
    end
    
endmodule