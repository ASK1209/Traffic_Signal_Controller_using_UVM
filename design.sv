// Code your design here
// ============================================================
//  Traffic Signal Controller
//
//  Single road traffic light FSM
//  States : RED → GREEN → YELLOW → RED → ...
//  Timing : RED=30, GREEN=25, YELLOW=5 clock cycles
//  Reset  : Active-low asynchronous (rst_n)
//  Enable : When enable=0, timer and state are frozen
//==============================================================
module traffic_signal_controller (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       enable,
    output logic [1:0] light,
    output logic       red,
    output logic       green,
    output logic       yellow
);
 
    // State encoding
    typedef enum logic [1:0] {
        RED_S    = 2'b00,
        GREEN_S  = 2'b01,
        YELLOW_S = 2'b10
    } state_e;
 
    // Timer durations (in clock cycles)
    parameter int RED_TIME    = 30;
    parameter int GREEN_TIME  = 25;
    parameter int YELLOW_TIME = 5;
 
    state_e       current_state, next_state;
    logic [4:0]   timer;
    logic         timer_done;
 
    // ── Timer ─────────────────────────────────────────────
    always @(posedge clk) begin
        if (!rst_n || !enable) begin
            timer <= 5'd0;
        end else begin
            if (timer_done)
                timer <= 5'd0;
            else
                timer <= timer + 1;
        end
    end
 
    // ── Timer Done logic ──────────────────────────────────
    always @(*) begin
        case (current_state)
            RED_S    : timer_done = (timer == RED_TIME    - 1);
            GREEN_S  : timer_done = (timer == GREEN_TIME  - 1);
            YELLOW_S : timer_done = (timer == YELLOW_TIME - 1);
            default  : timer_done = 1'b0;
        endcase
    end
 
    // ── State Register ────────────────────────────────────
    // BUG FIX: original code used 'rst' — corrected to '!rst_n'
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= RED_S;
        else if (enable)
            current_state <= next_state;
    end
 
    // ── Next State Logic ──────────────────────────────────
    always_comb begin
        next_state = current_state;
        if (timer_done) begin
            case (current_state)
                RED_S    : next_state = GREEN_S;
                GREEN_S  : next_state = YELLOW_S;
                YELLOW_S : next_state = RED_S;
                default  : next_state = RED_S;
            endcase
        end
    end
 
    // ── Output Logic ──────────────────────────────────────
    always_comb begin
    light  = RED_S;
    red    = 1'b1;
    green  = 1'b0;
    yellow = 1'b0;

    unique case (current_state)

        RED_S: begin
            light  = RED_S;
            red    = 1'b1;
            green  = 1'b0;
            yellow = 1'b0;
        end

        GREEN_S: begin
            light  = GREEN_S;
            red    = 1'b0;
            green  = 1'b1;
            yellow = 1'b0;
        end

        YELLOW_S: begin
            light  = YELLOW_S;
            red    = 1'b0;
            green  = 1'b0;
            yellow = 1'b1;
        end

        default: begin
            light  = RED_S;
            red    = 1'b1;
            green  = 1'b0;
            yellow = 1'b0;
        end

    endcase
end
 
endmodule