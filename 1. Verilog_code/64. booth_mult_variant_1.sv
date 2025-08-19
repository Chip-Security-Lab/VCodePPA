//SystemVerilog
module booth_mult (
    input clk,
    input rst_n,
    input req,
    output reg ack,
    input [7:0] X,
    input [7:0] Y,
    output reg [15:0] P,
    output reg result_ack
);

    // Pipeline stage 1: Input registers
    reg [7:0] X_reg;
    reg [7:0] Y_reg;
    reg req_reg;
    reg req_prev;
    
    // Pipeline stage 2: Initialization
    reg [15:0] A_init;
    reg [8:0] Q_init;
    reg [2:0] count_init;
    reg init_valid;
    
    // Pipeline stage 3: Booth encoding
    reg [15:0] A_enc;
    reg [8:0] Q_enc;
    reg [2:0] count_enc;
    reg [1:0] booth_enc;
    reg enc_valid;
    
    // Pipeline stage 4: Partial product generation
    reg [15:0] A_pp;
    reg [8:0] Q_pp;
    reg [2:0] count_pp;
    reg [15:0] partial_product;
    reg pp_valid;
    
    // Pipeline stage 5: Accumulation
    reg [15:0] A_acc;
    reg [8:0] Q_acc;
    reg [2:0] count_acc;
    reg acc_valid;
    
    // Pipeline stage 6: Shift
    reg [15:0] A_shift;
    reg [8:0] Q_shift;
    reg [2:0] count_shift;
    reg shift_valid;
    
    // Pipeline stage 7: Completion check
    reg [15:0] A_final;
    reg [2:0] count_final;
    reg done_valid;
    
    // Pipeline stage 8: Output
    reg [2:0] state;
    reg [15:0] P_reg;
    
    localparam IDLE = 3'b000;
    localparam CALC = 3'b001;
    localparam DONE = 3'b010;
    
    // Pipeline stage 1: Input registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            X_reg <= 8'b0;
            Y_reg <= 8'b0;
            req_reg <= 1'b0;
            req_prev <= 1'b0;
        end else begin
            X_reg <= X;
            Y_reg <= Y;
            req_reg <= req;
            req_prev <= req;
        end
    end
    
    // Pipeline stage 2: Initialization
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_init <= 16'b0;
            Q_init <= 9'b0;
            count_init <= 3'b0;
            init_valid <= 1'b0;
        end else begin
            if (req_reg && !req_prev) begin
                A_init <= 16'b0;
                Q_init <= {Y_reg, 1'b0};
                count_init <= 3'b0;
                init_valid <= 1'b1;
            end else begin
                init_valid <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 3: Booth encoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_enc <= 16'b0;
            Q_enc <= 9'b0;
            count_enc <= 3'b0;
            booth_enc <= 2'b0;
            enc_valid <= 1'b0;
        end else begin
            if (init_valid) begin
                A_enc <= A_init;
                Q_enc <= Q_init;
                count_enc <= count_init;
                booth_enc <= Q_init[1:0];
                enc_valid <= 1'b1;
            end else begin
                enc_valid <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 4: Partial product generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_pp <= 16'b0;
            Q_pp <= 9'b0;
            count_pp <= 3'b0;
            partial_product <= 16'b0;
            pp_valid <= 1'b0;
        end else begin
            if (enc_valid) begin
                A_pp <= A_enc;
                Q_pp <= Q_enc;
                count_pp <= count_enc;
                
                case(booth_enc)
                    2'b01: partial_product <= {X_reg, 8'b0};
                    2'b10: partial_product <= -{X_reg, 8'b0};
                    default: partial_product <= 16'b0;
                endcase
                
                pp_valid <= 1'b1;
            end else begin
                pp_valid <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 5: Accumulation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_acc <= 16'b0;
            Q_acc <= 9'b0;
            count_acc <= 3'b0;
            acc_valid <= 1'b0;
        end else begin
            if (pp_valid) begin
                A_acc <= A_pp + partial_product;
                Q_acc <= Q_pp;
                count_acc <= count_pp;
                acc_valid <= 1'b1;
            end else begin
                acc_valid <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 6: Shift
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_shift <= 16'b0;
            Q_shift <= 9'b0;
            count_shift <= 3'b0;
            shift_valid <= 1'b0;
        end else begin
            if (acc_valid) begin
                A_shift <= {A_acc[15], A_acc[15:1]};
                Q_shift <= {A_acc[0], Q_acc[8:1]};
                count_shift <= count_acc + 1;
                shift_valid <= 1'b1;
            end else begin
                shift_valid <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 7: Completion check
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_final <= 16'b0;
            count_final <= 3'b0;
            done_valid <= 1'b0;
        end else begin
            if (shift_valid) begin
                A_final <= A_shift;
                count_final <= count_shift;
                done_valid <= (count_shift >= 8);
            end else begin
                done_valid <= 1'b0;
            end
        end
    end
    
    // Pipeline stage 8: Output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            ack <= 1'b0;
            result_ack <= 1'b0;
            P <= 16'b0;
            P_reg <= 16'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (req_reg && !req_prev) begin
                        state <= CALC;
                        ack <= 1'b1;
                    end
                end
                
                CALC: begin
                    if (done_valid) begin
                        state <= DONE;
                        P <= A_final;
                        P_reg <= A_final;
                        result_ack <= 1'b1;
                    end
                end
                
                DONE: begin
                    result_ack <= 1'b0;
                    ack <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule