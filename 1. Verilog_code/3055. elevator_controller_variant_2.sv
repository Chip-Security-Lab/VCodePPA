//SystemVerilog
module elevator_controller_axi (
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel  
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Register map
    localparam FLOOR_REQUEST_REG = 8'h00;
    localparam UP_DOWN_REG = 8'h04;
    localparam CURRENT_FLOOR_REG = 8'h08;
    localparam STATUS_REG = 8'h0C;

    // Internal registers
    reg [3:0] floor_request;
    reg up_down;
    reg [3:0] current_floor;
    reg moving;
    reg door_open;
    
    // State machine states
    localparam IDLE=2'b00, MOVING=2'b01, DOOR_OPENING=2'b10, DOOR_CLOSING=2'b11;
    reg [1:0] state, next;
    reg [3:0] target_floor;
    reg [3:0] timer;
    
    // AXI-Lite write state machine
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    reg [1:0] write_state;
    
    // AXI-Lite read state machine
    localparam READ_IDLE = 2'b00;
    localparam READ_DATA = 2'b01;
    reg [1:0] read_state;

    // Write state machine
    always @(posedge aclk) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    if (s_axil_awvalid) begin
                        write_state <= WRITE_DATA;
                        s_axil_awready <= 1'b0;
                    end
                end
                
                WRITE_DATA: begin
                    s_axil_wready <= 1'b1;
                    if (s_axil_wvalid) begin
                        write_state <= WRITE_RESP;
                        s_axil_wready <= 1'b0;
                        // Write data to registers
                        case (s_axil_awaddr[7:0])
                            FLOOR_REQUEST_REG: floor_request <= s_axil_wdata[3:0];
                            UP_DOWN_REG: up_down <= s_axil_wdata[0];
                            default: ;
                        endcase
                    end
                end
                
                WRITE_RESP: begin
                    s_axil_bvalid <= 1'b1;
                    s_axil_bresp <= 2'b00;
                    if (s_axil_bready) begin
                        write_state <= WRITE_IDLE;
                        s_axil_bvalid <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Read state machine
    always @(posedge aclk) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    if (s_axil_arvalid) begin
                        read_state <= READ_DATA;
                        s_axil_arready <= 1'b0;
                        // Read data from registers
                        case (s_axil_araddr[7:0])
                            FLOOR_REQUEST_REG: s_axil_rdata <= {28'h0, floor_request};
                            UP_DOWN_REG: s_axil_rdata <= {31'h0, up_down};
                            CURRENT_FLOOR_REG: s_axil_rdata <= {28'h0, current_floor};
                            STATUS_REG: s_axil_rdata <= {30'h0, moving, door_open};
                            default: s_axil_rdata <= 32'h0;
                        endcase
                    end
                end
                
                READ_DATA: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00;
                    if (s_axil_rready) begin
                        read_state <= READ_IDLE;
                        s_axil_rvalid <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Elevator control logic
    wire floor_req_valid;
    wire floor_reached;
    wire door_open_timeout;
    wire door_close_timeout;
    wire move_up;
    
    assign floor_req_valid = |floor_request;
    assign floor_reached = (current_floor == target_floor);
    assign door_open_timeout = (timer >= 4'd10);
    assign door_close_timeout = (timer >= 4'd5);
    assign move_up = (current_floor < target_floor);
    
    always @(posedge aclk) begin
        if (!aresetn) begin
            state <= IDLE;
            current_floor <= 4'd0;
            timer <= 4'd0;
        end else begin
            state <= next;
            if (state == MOVING)
                current_floor <= move_up ? current_floor + 1'b1 : current_floor - 1'b1;
            timer <= (state != next) ? 4'd0 : timer + 1'b1;
        end
    end
    
    always @(*) begin
        moving = (state == MOVING);
        door_open = (state == DOOR_OPENING);
        next = state;
        
        case (state)
            IDLE: 
                if (floor_req_valid) begin
                    target_floor = floor_request;
                    next = floor_reached ? DOOR_OPENING : MOVING;
                end
            MOVING: 
                if (floor_reached) 
                    next = DOOR_OPENING;
            DOOR_OPENING: 
                if (door_open_timeout) 
                    next = DOOR_CLOSING;
            DOOR_CLOSING: 
                if (door_close_timeout) 
                    next = IDLE;
        endcase
    end

endmodule